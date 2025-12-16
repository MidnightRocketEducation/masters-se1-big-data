import Foundation;
import SwiftAvroCore;

actor BusinessProcessor {
	static let jsonDecoder: JSONDecoder = JSONDecoder();
	static let jsonEncoder: JSONEncoder = JSONEncoder();

	let avro = Avro();

	let stateManager: ProducerStateManager;
	let sourceFile: FileHandle;
	let cacheFileURL: URL;
	let categoryFilterURL: URL;

	var dictionary: [String: BusinessModel] = [:];

	init(stateManager: ProducerStateManager, sourceFile: URL, cacheFileURL: URL, categoryFilterURL: URL) throws {
		self.sourceFile = try FileHandle(forReadingFrom: sourceFile);
		self.stateManager = stateManager;
		self.cacheFileURL = cacheFileURL;
		self.categoryFilterURL = categoryFilterURL;
	}

	func processFile(kafkaProducer: @Sendable (BusinessModel, Data) async throws -> Void) async throws {
		if await self.stateManager.get(key: \.businessesFileState).completed {
			return;
		}
		_ = avro.decodeSchema(schema: try BusinessModel.avroSchemaString)

		let categoryFilter = try await CategoryFilter.load(from: try .init(forReadingFrom: self.categoryFilterURL));

		let reader = CancelableFileReading(file: sourceFile, state: await self.stateManager.get(key: \.businessesFileState));
		await reader.setSaveStateCallback() { state in
			try? await self.stateManager.update(key: \.businessesFileState, to: state);
		}

		try await AtomicFileWriter.write(to: self.cacheFileURL, mode: .append) { writer in
			let newline = Data("\n".utf8);
			let (state, reason) = await reader.read() { line in
				let model = try await self.jsonDecode(line) { m in
					return categoryFilter.matches(categoryArray: m.categories)
				}
				guard let model else {
					return;
				}
				let data = try Self.jsonEncoder.encode(model) + newline;
				let avroData = try await self.avroEncode(model);
				try await kafkaProducer(model, avroData);
				try await writer.write(data: data);
			}
			try await self.stateManager.update(key: \.businessesFileState, to: state);
			try reason.resolve();
		}
	}

	func loadCacheFile() async throws {
		guard FileManager.default.fileExists(atPath: self.cacheFileURL.path()) else {
			return;
		}

		for try await line in AsyncLineSequenceFromFile(from: try .init(forReadingFrom: self.cacheFileURL)) {
			_ = try self.jsonDecode(line);
		}
	}

	func avroEncode(_ value: BusinessModel) throws -> Data {
		return try self.avro.encode(value);
	}

	func avroDecode(_ line: String) throws -> BusinessModel {
		let model: BusinessModel = try self.avro.decode(from: Data(line.utf8));
		self.dictionary[model.id] = model;
		return model;
	}

	func jsonDecode(_ line: String, filter: ((BusinessModel) -> Bool)? = nil) throws -> BusinessModel? {
		let model = try Self.jsonDecoder.decode(BusinessModel.self, from: Data(line.utf8));
		if let filter, !filter(model) {
			return nil;
		}
		self.dictionary[model.id] = model;
		return model;
	}
}
