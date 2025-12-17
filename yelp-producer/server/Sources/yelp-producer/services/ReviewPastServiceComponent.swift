
struct ReviewPastServiceComponent: ServiceComponent {
	let config: GlobalConfiguration;
	let processor: ReviewProcessor;
	let batchProcessor: AsyncLimitedBatchProcessor;

	init(config: GlobalConfiguration, businesses: [String: BusinessModel]) async throws {
		self.config = config;
		self.processor = try ReviewProcessor(
			stateManager: (get: {await config.stateManager.get(key: \.reviewsFileStatePast)}, update: { try await config.stateManager.update(key: \.reviewsFileStatePast, to: $0)}),
			sourceFile: config.options.sourceDirectory + YelpFilenames.reviewsPast,
			businesses: businesses
		);
		self.batchProcessor = await AsyncLimitedBatchProcessor(batchSize: 50);
	}

	func run() async throws -> Void {
		try await self.processor.processFile { model, data in
			try await self.batchProcessor.add {
				try? await self.config.kafkaService.postTo(topic: .reviewsEvent, message: data);
			}
		}
	}

	func cancel() async {
		await self.processor.cancel();
		await self.batchProcessor.cancel();
	}
}
