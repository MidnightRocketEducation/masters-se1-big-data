import Foundation;

struct AsyncLineSequenceFromFile: AsyncSequence {
	fileprivate static let lineSeperator = "\n";
	fileprivate static let BUFFER_SIZE: Int = 16_384;

	typealias Element = String;

	private let fileHandle: FileHandle;

	init(from fileHandle: FileHandle) {
		self.fileHandle = fileHandle;
	}

	struct AsyncIterator: AsyncIteratorProtocol {
		private let fileHandle: FileHandle;
		private var lines: [String.SubSequence] = [];

		init(_ fileHandle: FileHandle) {
			self.fileHandle = fileHandle
		}

		mutating func next() async throws -> Element? {
			if self.lines.count <= 1 {
				// try to read more if one line or less is left
				try self.readMore();
			}

			if self.lines.isEmpty {
				// return nil if still empty
				return nil;
			}

			return String(self.lines.removeFirst());
		}

		private mutating func readMore() throws {
			guard let data = try self.fileHandle.read(upToCount: AsyncLineSequenceFromFile.BUFFER_SIZE) else {
				// Return if no more data left
				return;
			}

			guard let newString = String(data: data, encoding: .utf8) else {
				throw Error.encodeError;
			}

			/*
			 Combine current lines into string.
			 Then add the new string and again split by lines.
			 This prevents broken lines across buffer berriers.
			 */
			let currentStr = self.lines.joined(separator: AsyncLineSequenceFromFile.lineSeperator);
			self.lines = (currentStr + newString).split(separator: AsyncLineSequenceFromFile.lineSeperator);
		}

		enum Error: Swift.Error {
			case encodeError;
		}
	}

	func makeAsyncIterator() -> AsyncIterator {
		return AsyncIterator(self.fileHandle);
	}
}
