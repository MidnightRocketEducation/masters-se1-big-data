
struct ReviewFutureServiceComponent: ServiceComponent {
	let config: GlobalConfiguration;
	let processor: ReviewProcessor;
	let batchProcessor: AsyncLimitedBatchProcessor;

	init(config: GlobalConfiguration, businesses: [String: BusinessModel]) async throws {
		self.config = config;
		self.processor = try ReviewProcessor(
			stateManager: (
				get: {await config.stateManager.get(key: \.reviewsFileStateFuture)},
				update: {try await config.stateManager.update(key: \.reviewsFileStateFuture, to: $0)}
			),
			sourceFile: config.options.sourceDirectory + YelpFilenames.reviewsFuture,
			businesses: businesses,
			schemaID: await config.stateManager.get(key: \.reviewSchemaID) ?? .init(id: 0)
		);
		self.batchProcessor = await AsyncLimitedBatchProcessor();
	}

	func run() async throws -> Void {
			self.config.logger.info("Begin import \(YelpFilenames.reviewsFuture)");
			try await self.processFiles();
			self.config.logger.info("Done import \(YelpFilenames.reviewsFuture)");
	}

	func processFiles() async throws {
		try await self.processor.processFile { model, data in
			var date = try await self.config.clock.getWithSafeContinuity();
			if model.date > date {
				self.config.logger.info("Waiting for clock to advance to at least: \(model.date.ISO8601Format())");
				date = try await self.config.clock.waitUntilWithSafeContinuity { model.date <= $0 }
				self.config.logger.info("Done waiting. Worldclock updated to: \(date.ISO8601Format())");
			}

			try await self.batchProcessor.add {
				do {
					try await self.config.kafkaProducerService.postTo(topic: .reviewEvent, message: data);
				} catch {
					self.config.logger.error("Failed to publish to kafka: \(error)");
				}
			}

			try await self.config.stateManager.update(key: \.clockState, to: date);
		}
	}

	func cancel() async {
		await self.processor.cancel();
		await self.batchProcessor.cancel();
		await self.config.clock.cancelAll();
	}
}
