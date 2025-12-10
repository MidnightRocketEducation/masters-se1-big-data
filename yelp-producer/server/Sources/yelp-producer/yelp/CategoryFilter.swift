import Foundation;

struct CategoryFilter {
	private let set: Set<String>;

	func matches(categoryString: String, threshold: Int = 3, separator: String = ", ") -> Bool {
		var count = 0;
		for category in categoryString.split(separator: separator) {
			if count >= threshold {
				return true;
			}
			if set.contains(String(category)) {
				count += 1;
			}
		}
		return false;
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
