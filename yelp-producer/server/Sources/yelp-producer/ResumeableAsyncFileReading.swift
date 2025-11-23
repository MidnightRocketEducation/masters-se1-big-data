import Foundation;

struct ResumeableAsyncFileReading: AsyncSequence {
	typealias Element = (state: FileReadingState, line: String);

	let fileHandle: FileHandle;

	init(fileHandle: FileHandle) {
		self.fileHandle = fileHandle;
	}

	struct AsyncIterator: AsyncIteratorProtocol {
		let filehandle: FileHandle;
		var linesIterator: AsyncLineSequence<FileHandle.AsyncBytes>.AsyncIterator;
		var lineOffset: Int = 0;
		var previousByteOffset: UInt64;
		var currentByteOffset: UInt64;

		init(fileHandle: FileHandle) {
			self.filehandle = fileHandle;
			self.previousByteOffset = (try? fileHandle.offset()) ?? 0;
			self.linesIterator = fileHandle.bytes.lines.makeAsyncIterator();
			self.currentByteOffset = self.previousByteOffset;
		}

		mutating func next() async throws -> Element? {
			guard let line = try await self.linesIterator.next() else {
				return nil;
			}

			let state = (FileReadingState(
				byteOffset: self.previousByteOffset,
				lineOffset: self.lineOffset
			), line);

			let nextByteOffset = try filehandle.offset();
			if self.currentByteOffset != nextByteOffset {
				self.previousByteOffset = self.currentByteOffset;
				self.currentByteOffset = nextByteOffset;
				self.lineOffset = 0;
			}

			self.lineOffset+=1;
			return state;
		}
	}

	func makeAsyncIterator() -> AsyncIterator {
		Self.AsyncIterator(fileHandle: self.fileHandle);
	}

	mutating func resume(state: FileReadingState) throws -> AsyncDropFirstSequence<Self> {
		try self.fileHandle.seek(toOffset: state.byteOffset);
		return self.dropFirst(state.lineOffset);
	}
}


struct FileReadingState: Codable {
	let byteOffset: UInt64;
	let lineOffset: Int;
}
