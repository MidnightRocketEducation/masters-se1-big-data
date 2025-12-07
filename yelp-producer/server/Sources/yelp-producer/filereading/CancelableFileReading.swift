import Foundation;

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

				do {
					try await reader(line.line);
				} catch {
					throw Error.readerError(error, State(completed: false, offset: currentOffset));
				}

				currentOffset = line.offset;
			}
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
