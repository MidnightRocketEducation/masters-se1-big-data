import Foundation;
import ServiceLifecycle;

actor CancelableFileReading {
	private let file: ResumeableAsyncFileReading;
	private var state: State;
	private var cancelled: Bool = false;

	let saveQueue = AsyncQueueProcessor<Void>();
	private var saveStateCallback: (@Sendable (State) async -> Void)? = nil;
	private var saveInterval: UInt = 50;

	init(file: FileHandle, state: State = State.new) {
		self.file = ResumeableAsyncFileReading(fileHandle: file);
		self.state = state;
	}

	func setSaveStateCallback(interval: UInt? = nil, _ callback: @escaping (@Sendable (State) async -> Void)) {
		if let interval = interval {
			self.saveInterval = interval;
		}

		self.saveStateCallback = callback;
	}

	func cancel() async {
		self.cancelled = true;
	}
}

extension CancelableFileReading {
	/**
	 Read file line by line. The provided closure is called with each line as its argument.
	 Only atmost line is processed at a time.
	 The returned ``State`` represent the line which has last been succesfully processed by the `reader` closure.
	 */
	func read(using reader: @Sendable (String) async throws -> Void) async -> ReaderReturn {
		let result = await self._read(using: reader);
		await saveQueue.add {
			await self.saveStateCallback?(result.state);
		}
		_ = await saveQueue.finish();
		return result;
	}

	private func _read(using reader: (String) async throws -> Void) async -> ReaderReturn {
		do {
			return try await self.processLines(using: reader);
		} catch {
			return (self.state, .error(error));
		}
	}

	private func processLines(using reader: (String) async throws -> Void) async throws -> ReaderReturn {
		guard !self.state.completed else {
			return (self.state, .completed);
		}
		var count: UInt = 1;
		for try await (line, offset) in try file.resume(from: self.state.offset) {
			guard !self.cancelled else {
				return (self.state, .cancelled);
			}
			try await reader(line);

			self.state.offset = offset;

			if let saveStateCallback, ++count >= self.saveInterval {
				count = 0;
				await self.saveQueue.add {
					await saveStateCallback(self.state);
				}
			}
		}
		self.state.completed = true;
		return (state, .completed);
	}
}


extension CancelableFileReading {
	struct State: Codable {
		static let new: Self = .init(completed: false, offset: .zero);

		var completed: Bool;
		var offset: ResumeableAsyncFileReading.Offset;
	}

	typealias ReaderReturn = (state: State, reason: TerminationReason);

	enum TerminationReason {
		case completed;
		case cancelled;
		case error(Swift.Error);

		/**
		 Throws the contained ``Error`` if the reason is ``.error``.
		 Otherwise returns `self`.
		 */
		@discardableResult
		func resolve() throws -> Self {
			switch self {
			case .error(let error): throw error;
			default: return self;
			}
		}
	}
}


actor FileReadingService: Service {
	let file: FileHandle;

	init(file: FileHandle) {
		self.file = file;
	}

	func run() async throws {
		let cancelableReader = CancelableFileReading(file: self.file, state: fetchState() ?? .new);
		async let _ = onCancel {
			await cancelableReader.cancel();
		}

		let (state, _) = await cancelableReader.read() { line in
			print(line);
		}
		try saveState(state);
	}

	func onCancel(_ f: () async -> Void) async {
		try? await gracefulShutdown();
		await f();
	}
}
