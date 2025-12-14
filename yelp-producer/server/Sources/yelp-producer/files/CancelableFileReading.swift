import Foundation;
import ServiceLifecycle;

actor CancelableFileReading {
	private let file: ResumeableAsyncFileReading;
	private let state: State;
	private var cancelled: Bool = false;

	init(file: FileHandle, state: State = State.new) {
		self.file = ResumeableAsyncFileReading(fileHandle: file);
		self.state = state;
	}

	/**
	 Read file line by line. The provided closure is called with each line as its argument.
	 Only atmost line is processed at a time.
	 The returned ``State`` represent the line which has last been succesfully processed by the `reader` closure.
	 */
	func read(using reader: (String) async throws -> Void) async -> ReaderReturn {
		guard !state.completed else {
			return (self.state, .completed);
		}

		var currentState: State = self.state;

		do {
			for try await (line, offset) in try file.resume(from: self.state.offset) {
				guard !self.cancelled else {
					return (currentState, .cancelled);
				}

				try await reader(line);

				currentState.offset = offset;
			}
		} catch {
			return (currentState, .error(error));
		}
		currentState.completed = true;
		return (currentState, .completed);
	}

	func cancel() async {
		self.cancelled = true;
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

		let (state, reason) = await cancelableReader.read() { line in
			print(line);
		}
		try saveState(state);
	}

	func onCancel(_ f: () async -> Void) async {
		try? await gracefulShutdown();
		await f();
	}
}
