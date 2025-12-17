struct BusinessServiceComponent: ServiceComponent {
	let processor: BusinessProcessor;
	let batchProcessor: AsyncLimitedBatchProcessor;
	let config: GlobalConfiguration;

	init(config: GlobalConfiguration) async throws {
		self.config = config;
		self.processor = try BusinessProcessor(config: config);
		self.batchProcessor = await AsyncLimitedBatchProcessor(batchSize: 50);
	}

	func run() async throws -> [String: BusinessModel] {
		try await processor.loadCacheFile();
		try await processor.processFile() { model, data in
			try await batchProcessor.add {
				try? await config.kafkaService.postTo(topic: .BusinessEvents, message: data);
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
