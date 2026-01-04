import Foundation;

struct CategoryFilter {
	private let set: Set<String>;

	func matches(categoryArray: [some StringProtocol], threshold: Int = 3) -> Bool {
		var count = 0;
		for category in categoryArray {
			if self.set.contains(String(category)) {
				if ++count >= threshold {
					return true;
				}
			}
		}
		return false;
	}

	func matches(categoryString: String, threshold: Int = 3, separator: String = ", ") -> Bool {
		return self.matches(categoryArray: categoryString.split(separator: separator), threshold: threshold);
	}
}

extension CategoryFilter {
	static func load(from file: FileHandle) async throws -> Self {
		var set: Set<String> = [];
		let reader = AsyncLineSequenceFromFile(from: file);
		for try await line in reader {
			set.insert(String(line));
		}
		return .init(set: set);
	}
}
