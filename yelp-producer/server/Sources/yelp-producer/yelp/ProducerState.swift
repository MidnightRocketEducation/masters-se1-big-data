import Foundation;
public struct ProducerState: Codable {
	var businessesFileState: CancelableFileReading.State;
	var reviewsFileStatePast: CancelableFileReading.State;
	var reviewsFileStateFuture: CancelableFileReading.State;
	var hasUploadedSchema: Bool;
	var clockState: Date;
}

extension ProducerState {
	static var empty: ProducerState {
		.init(
			businessesFileState: .new,
			reviewsFileStatePast: .new,
			reviewsFileStateFuture: .new,
			hasUploadedSchema: false,
			clockState: .distantPast
		);
	}
}

extension ProducerState {
	private static let encoder: JSONEncoder = {
		let encoder = JSONEncoder();
		encoder.dateEncodingStrategy = .iso8601;
		return encoder;
	}();

	static func readFrom(file url: URL) throws -> ProducerState {
		guard FileManager.default.fileExists(atPath: url.path()) else {
			return .empty;
		}
		let decoder = JSONDecoder();
		decoder.dateDecodingStrategy = .iso8601;
		return try decoder.decode(ProducerState.self, from: try Data(contentsOf: url));
	}

	func write(to url: URL) throws {
		try Self.encoder.encode(self).write(to: url, options: .atomic);
	}
}


public actor ProducerStateManager {
	private var state: ProducerState;
	private var url: URL;

	init(file url: URL) throws {
		self.state = try .readFrom(file: url);
		self.url = url;
	}

	public func update<Value>(key: WritableKeyPath<ProducerState, Value>, to newValue: Value) async throws {
		self.state[keyPath: key] = newValue;
		try self.writeToDisk();
	}

	public func get<Value>(key: KeyPath<ProducerState, Value>) -> Value {
		self.state[keyPath: key];
	}

	func writeToDisk() throws {
		try state.write(to: url);
	}

	typealias IsolatedStateView<Value> = (get: @Sendable () async -> (Value), update: @Sendable (Value) async throws -> ())
}


enum StateFileNames: String {
	case main = "state.json";
	case processedBusinesses = "processed-businesses.jsonl";
}
