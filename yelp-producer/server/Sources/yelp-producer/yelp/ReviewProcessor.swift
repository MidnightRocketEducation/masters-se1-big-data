import Foundation;

actor ReviewProcessor {
	let stateManager: ProducerStateManager;
	let sourceFile: FileHandle;
	let businesses: [String: BusinessModel];


	init(stateManager: ProducerStateManager, sourceFile: URL, businesses: [String: BusinessModel]) throws {
		self.sourceFile = try FileHandle(forReadingFrom: sourceFile);
		self.stateManager = stateManager;
		self.businesses = businesses;
	}

	func processFile(kafkaProducer: @Sendable (ReviewModel, Data) async throws -> Void) async throws {
		if await self.stateManager.get(key: \.businessesFileState).completed {
			return;
		}


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

				let data = try ReviewModel.jsonEncoder.encode(model) + newline;
				try await kafkaProducer(model, data);
			}
			try await self.stateManager.update(key: \.businessesFileState, to: state);
			try reason.resolve();
	}

	func decode(_ line: String, filter: ((ReviewModel) -> Bool)? = nil) throws -> ReviewModel? {
		let model = try ReviewModel.jsonDecoder.decode(ReviewModel.self, from: Data(line.utf8));
		if let filter, !filter(model) {
			return nil;
		}
		return model;
	}
}
