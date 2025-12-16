import Foundation;
struct ProducerState: Codable {
	var businessesFileState: CancelableFileReading.State;
	var reviewsFileState: CancelableFileReading.State;
	var hasUploadedSchema: Bool;
}

extension ProducerState {
	static var empty: ProducerState {
		.init(
			businessesFileState: .new,
			reviewsFileState: .new,
			hasUploadedSchema: false
		);
	}
}

extension ProducerState {
	static func readFrom(file url: URL) throws -> ProducerState {
		guard FileManager.default.fileExists(atPath: url.path()) else {
			return .empty;
		}
		let decoder = JSONDecoder();
		return try decoder.decode(ProducerState.self, from: try Data(contentsOf: url));
	}

	func write(to url: URL) throws {
		let encoder = JSONEncoder();
		try encoder.encode(self).write(to: url, options: .atomic);
	}
}


actor ProducerStateManager {
	private var state: ProducerState;
	private var url: URL;

	init(file url: URL) throws {
		self.state = try .readFrom(file: url);
		self.url = url;
	}

	func update<Value>(key: WritableKeyPath<ProducerState, Value>, to newValue: Value) async throws {
		self.state[keyPath: key] = newValue;
		try self.writeToDisk();
	}

	func get<Value>(key: KeyPath<ProducerState, Value>) -> Value {
		self.state[keyPath: key];
	}

	func writeToDisk() throws {
		try state.write(to: url);
	}
}


enum StateFileNames: String {
	case main = "state.json";
	case processedBusinesses = "processed-businesses.jsonl";
}
