import Foundation;
import Avro;

actor BusinessProcessor {
	static let jsonDecoder: JSONDecoder = JSONDecoder();
	static let jsonEncoder: JSONEncoder = JSONEncoder();
	static let newline = Data("\n".utf8);

	let avroEncoder: AvroEncoder;
	let avroDecoder: AvroDecoder;

	let stateManager: ProducerStateManager;
	let sourceFile: FileHandle;
	let cacheFileURL: URL;
	let categoryFilterURL: URL;
	let config: GlobalConfiguration;

	var dictionary: [String: BusinessModel] = [:];

	var cancelHandle: (() async -> Void)? = nil;

	init(config: GlobalConfiguration) throws {
		self.sourceFile = try FileHandle(forReadingFrom: config.options.sourceDirectory + YelpFilenames.businesses);
		self.stateManager = config.stateManager;
		self.cacheFileURL = config.options.stateDirectory + StateFileNames.processedBusinesses;
		self.categoryFilterURL = config.options.categoryFile;
		self.avroEncoder = AvroEncoder(schema: BusinessModel.avroSchema);
		self.avroDecoder = AvroDecoder(schema: BusinessModel.avroSchema);
		self.config = config;
	}

	func processFile(kafkaProducer: @Sendable (BusinessModel, Data) async throws -> Void) async throws {
		if await self.stateManager.get(key: \.businessesFileState).completed {
			self.config.logger.info("Businesses file already fully processed.");
			return;
		}

		let categoryFilter = try await CategoryFilter.load(from: try .init(forReadingFrom: self.categoryFilterURL));

		let reader = CancelableFileReading(file: sourceFile, state: await self.stateManager.get(key: \.businessesFileState));
		self.cancelHandle = reader.cancel;

		try await AtomicFileWriter.write(to: self.cacheFileURL, mode: .append) { writer in
			await reader.setSaveStateCallback() { state in
				do {
					try await writer.flush();
					try await self.stateManager.update(key: \.businessesFileState, to: state);
				} catch {
					self.config.logger.error("Failed to update business cache file: \(error)");
				}
			}

			let (_, reason) = await reader.read() { line in
				let model = try await self.jsonDecode(line) { m in
					return categoryFilter.matches(categoryArray: m.categories)
				}
				guard let model else {
					return;
				}
				let data = try Self.jsonEncoder.encode(model) + Self.newline;
				let avroData = try await self.avroEncode(model);
				try await kafkaProducer(model, avroData);
				try await writer.write(data: data);
			}

			try reason.resolve();
		}
	}

	func cancel() async {
		if let cancelHandle {
			await cancelHandle();
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
		return try self.avroEncoder.encode(value);
	}

	func avroDecode(_ line: String) throws -> BusinessModel {
		let model: BusinessModel = try self.avroDecoder.decode(BusinessModel.self, from: Data(line.utf8));
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
