import Foundation;

struct ResumeableAsyncFileReading: AsyncSequence {
	typealias Element = (line: String, offset: Offset);

	private let fileHandle: FileHandle;

	init(fileHandle: FileHandle) {
		self.fileHandle = fileHandle;
	}

	struct AsyncIterator: AsyncIteratorProtocol {
		let filehandle: FileHandle;
		var linesIterator: AsyncLineSequenceFromFile.AsyncIterator;
		var lineOffset: Int = 0;
		var previousByteOffset: UInt64;
		var currentByteOffset: UInt64;

		init(fileHandle: FileHandle) {
			self.filehandle = fileHandle;
			self.previousByteOffset = (try? fileHandle.offset()) ?? 0;
			self.linesIterator = AsyncLineSequenceFromFile(from: fileHandle).makeAsyncIterator();
			self.currentByteOffset = self.previousByteOffset;
		}

		mutating func next() async throws -> Element? {
			guard let line = try await self.linesIterator.next() else {
				return nil;
			}

			let offset = Offset(
				byteOffset: self.previousByteOffset,
				lineOffset: self.lineOffset,
			);

			let nextByteOffset = try filehandle.offset();
			if self.currentByteOffset != nextByteOffset {
				self.previousByteOffset = self.currentByteOffset;
				self.currentByteOffset = nextByteOffset;
				self.lineOffset = 0;
			}

			self.lineOffset+=1;
			return (line, offset);
		}
	}

	func makeAsyncIterator() -> AsyncIterator {
		Self.AsyncIterator(fileHandle: self.fileHandle);
	}

	func resume(from state: Offset) throws -> AsyncDropFirstSequence<Self> {
		try self.fileHandle.seek(toOffset: state.byteOffset);
		return self.dropFirst(state.lineOffset);
	}
}


extension ResumeableAsyncFileReading {
	struct Offset: Codable {
		static let zero: Offset = .init(byteOffset: 0, lineOffset: 0);

		let byteOffset: UInt64;
		let lineOffset: Int;
	}
}
