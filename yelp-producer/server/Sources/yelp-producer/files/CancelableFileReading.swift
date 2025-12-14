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
	func read(using reader: (String) async throws -> Void) async throws(Error) -> State {
		guard !state.completed else {
			return self.state;
		}

		var currentOffset: ResumeableAsyncFileReading.Offset = self.state.offset;

		do {
			for try await line in try file.resume(from: self.state.offset) {
				guard !self.cancelled else {
					throw Error.cancelled(State(completed: false, offset: currentOffset));
				}

				try await reader(line.line);

				currentOffset = line.offset;
			}
		} catch let error as Error {
			throw error;
		} catch {
			throw Error.readerError(error, State(completed: false, offset: currentOffset));
		}
		return State(completed: true, offset: currentOffset);
	}

	func cancel() async {
		self.cancelled = true;
	}
}


extension CancelableFileReading {
	struct State: Codable {
		static let new: Self = .init(completed: false, offset: .zero);

		let completed: Bool;
		let offset: ResumeableAsyncFileReading.Offset;
	}

	enum Error: Swift.Error {
		case cancelled(State);
		case readerError(Swift.Error, State);
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

		do {
			let state = try await cancelableReader.read() { line in
				print(line);
			}
			try saveState(state);
		} catch let e as CancelableFileReading.Error {
			switch e {
			case .readerError(_, let state):
				try saveState(state);
				fallthrough;
			default:
				throw e;
			}
		}

	}

	func onCancel(_ f: () async -> Void) async {
		try? await gracefulShutdown();
		await f();
	}
}
