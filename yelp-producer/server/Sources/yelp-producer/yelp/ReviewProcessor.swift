import Foundation;
import SwiftAvroCore;

actor ReviewProcessor {
	let stateManager: ProducerStateManager;
	let sourceFile: FileHandle;
	let businesses: [String: BusinessModel];
	let avro = Avro();
	var until: Date? = nil;


	init(stateManager: ProducerStateManager, sourceFile: URL, businesses: [String: BusinessModel]) throws {
		self.sourceFile = try FileHandle(forReadingFrom: sourceFile);
		self.stateManager = stateManager;
		self.businesses = businesses;
	}

	func processFile(kafkaProducer: @Sendable (ReviewModel, Data) async throws -> Void) async throws {
		if await self.stateManager.get(key: \.businessesFileState).completed {
			return;
		}

		_ = self.avro.decodeSchema(schema: try ReviewModel.avroSchemaString);

		let reader = CancelableFileReading(file: sourceFile, state: await self.stateManager.get(key: \.businessesFileState));
		await reader.setSaveStateCallback() { state in
			try? await self.stateManager.update(key: \.businessesFileState, to: state);
		}

		let newline = Data("\n".utf8);
		let (state, reason) = await reader.read() { line in
			let model = try await self.decode(line) { m in
				self.businesses[m.id] != nil;
			}

			guard let model else {
				return;
			}

			if let until = await self.until, model.date > until {
				throw Error.reachedCutoffDate;
			}

			let data = try ReviewModel.jsonEncoder.encode(model) + newline;
			try await kafkaProducer(model, data);
		}
		try await self.stateManager.update(key: \.businessesFileState, to: state);

		do {
			try reason.resolve();
		} catch let error as Error {
			switch error {
			case Error.reachedCutoffDate:
				break;
			}
		}
	}

	func decode(_ line: String, filter: ((ReviewModel) -> Bool)? = nil) throws -> ReviewModel? {
		let model = try ReviewModel.jsonDecoder.decode(ReviewModel.self, from: Data(line.utf8));
		if let filter, !filter(model) {
			return nil;
		}
		return model;
	}

	enum Error: Swift.Error {
		case reachedCutoffDate;
	}
}
