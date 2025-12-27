struct BusinessServiceComponent: ServiceComponent {
	let processor: BusinessProcessor;
	let batchProcessor: AsyncLimitedBatchProcessor;
	let config: GlobalConfiguration;

	init(config: GlobalConfiguration) async throws {
		self.config = config;
		self.processor = try BusinessProcessor(config: config);
		self.batchProcessor = await AsyncLimitedBatchProcessor();
	}

	func run() async throws -> [String: BusinessModel] {
		self.config.logger.info("Importing businesses...");
		self.config.logger.info("Loading business cache...");
		try await processor.loadCacheFile();
		self.config.logger.info("Processing business data...");
		try await processor.processFile() { model, data in
			try await batchProcessor.add {
				do {
					try await config.kafkaProducerService.postTo(topic: .businessEvent, message: data);
				} catch {
					config.logger.error("Failed to publish to kafka: \(error)");
				}
			}
		}
		await batchProcessor.cancel();
		let count = await self.processor.dictionary.count;
		config.logger.info("Done importing businesses: \(count)");
		return await self.processor.dictionary;
	}

	func cancel() async {
		await self.processor.cancel();
		await self.batchProcessor.cancel();
	}
}
