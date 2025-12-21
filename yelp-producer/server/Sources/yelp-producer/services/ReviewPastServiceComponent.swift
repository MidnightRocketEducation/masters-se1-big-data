
struct ReviewPastServiceComponent: ServiceComponent {
	let config: GlobalConfiguration;
	let processor: ReviewProcessor;
	let batchProcessor: AsyncLimitedBatchProcessor;

	init(config: GlobalConfiguration, businesses: [String: BusinessModel]) async throws {
		self.config = config;
		self.processor = try ReviewProcessor(
			stateManager: (
				get: {await config.stateManager.get(key: \.reviewsFileStatePast)},
				update: {try await config.stateManager.update(key: \.reviewsFileStatePast, to: $0)}
			),
			sourceFile: config.options.sourceDirectory + YelpFilenames.reviewsPast,
			businesses: businesses
		);
		self.batchProcessor = await AsyncLimitedBatchProcessor();
	}

	func run() async throws -> Void {
		self.config.logger.info("Starting to process \(YelpFilenames.reviewsPast)")
		try await self.processor.processFile { model, data in
			try await self.batchProcessor.add {
				do {
					try await self.config.kafkaProducerService.postTo(topic: .reviewsEvent, message: data);
				} catch {
					self.config.logger.error("Failed to publish to kafka: \(error)");
				}
			}
		}
		self.config.logger.info("Done import \(YelpFilenames.reviewsPast)");
	}

	func cancel() async {
		await self.processor.cancel();
		await self.batchProcessor.cancel();
	}
}
