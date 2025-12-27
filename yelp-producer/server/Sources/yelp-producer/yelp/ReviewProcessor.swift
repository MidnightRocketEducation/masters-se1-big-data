import Foundation;
// import SwiftAvroCore;
import Avro;

actor ReviewProcessor {
	typealias StateM = ProducerStateManager.IsolatedStateView<CancelableFileReading.State>
	let stateManager: StateM;
	let sourceFile: FileHandle;
	let businesses: [String: BusinessModel];
	let avro = AvroEncoder(schema: ReviewModel.avroSchema);
	var until: Date? = nil;
	var cancelHandle: @Sendable () async -> Void = {}


	init(stateManager: StateM, sourceFile: URL, businesses: [String: BusinessModel]) throws {
		self.sourceFile = try FileHandle(forReadingFrom: sourceFile);
		self.stateManager = stateManager;
		self.businesses = businesses;
	}

	func processFile(kafkaProducer: @Sendable (ReviewModel, Data) async throws -> Void) async throws {
		if await self.stateManager.get().completed {
			return;
		}

		let reader = CancelableFileReading(file: sourceFile, state: await self.stateManager.get());
		self.cancelHandle = reader.cancel;
		await reader.setSaveStateCallback() { state in
			try? await self.stateManager.update(state);
		}

		let (_, reason) = await reader.read { line in
			let model = try await self.decode(line) { m in
				return self.businesses[m.businessId] != nil;
			}

			guard let model else {
				return;
			}

			if let until = await self.until, model.date > until {
				throw Error.reachedCutoffDate;
			}

			let avroData = try await self.avroEncode(model);
			try await kafkaProducer(model, avroData);
		}

		do {
			try reason.resolve();
		} catch let error as Error {
			switch error {
			case Error.reachedCutoffDate:
				break;
			}
		}
	}

	func cancel() async {
		await self.cancelHandle();
	}

	func decode(_ line: String, filter: ((ReviewModel) -> Bool)? = nil) throws -> ReviewModel? {
		let model = try ReviewModel.jsonDecoder.decode(ReviewModel.self, from: Data(line.utf8));
		if let filter, !filter(model) {
			return nil;
		}
		return model;
	}

	func avroEncode(_ value: ReviewModel) throws -> Data {
		return try self.avro.encode(value);
	}

	enum Error: Swift.Error {
		case reachedCutoffDate;
	}
}
