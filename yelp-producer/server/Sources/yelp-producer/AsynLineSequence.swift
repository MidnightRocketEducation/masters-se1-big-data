import Foundation;

struct AsyncLineSequenceFromFile: AsyncSequence {
	fileprivate static let lineSeperator = "\n";
	typealias Element = String;

	private let fileHandle: FileHandle;

	init(from fileHandle: FileHandle) {
		self.fileHandle = fileHandle;
	}

	struct AsyncIterator: AsyncIteratorProtocol {
		private let fileHandle: FileHandle;
		private var data: Data = Data();
		private var lines: [String.SubSequence]? = [];

		init(_ fileHandle: FileHandle) {
			self.fileHandle = fileHandle
		}

		mutating func next() async throws -> Element? {
			guard let lines = self.lines else {
				return nil
			}

			if lines.count <= 1 {
				try self.readMore();
			}
			if let lines = self.lines, lines.count <= 0 {
				return nil;
			}

			return (self.lines?.removeFirst()).map(String.init);
		}

		private mutating func readMore() throws {
			guard let data = try self.fileHandle.read(upToCount: 32_000) else {
				//self.lines = nil;
				return;
			}

			let string: String = String(data: data, encoding: .utf8) ?? "";
			let currentStr = self.lines?.joined(separator: AsyncLineSequenceFromFile.lineSeperator) ?? "";
			self.lines = (currentStr + string).split(separator: AsyncLineSequenceFromFile.lineSeperator);
		}
	}

	func makeAsyncIterator() -> AsyncIterator {
		return AsyncIterator(self.fileHandle);
	}
}
