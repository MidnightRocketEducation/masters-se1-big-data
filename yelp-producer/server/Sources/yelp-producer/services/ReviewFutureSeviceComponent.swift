
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
			sourceFile: config.options.sourceDirectory + YelpFilenames.reviewsPast,
			businesses: businesses
		);
		self.batchProcessor = await AsyncLimitedBatchProcessor(batchSize: 50);
	}

	func run() async throws -> Void {
		do {
			try await self.processFiles();
			self.config.logger.info("Done import reviews.future");
		} catch let error as ClockContinuity.Error {
			guard case .waitCancelled = error else {
				throw error;
			}
			self.config.logger.info("Clock wait cancelled. Exiting.")
		}
	}

	func processFiles() async throws {
		try await self.processor.processFile { model, data in
			if await (model.date > self.config.clock.currentTime.date) {
				self.config.logger.info("Waiting for clock to advance");
			}
			let date = try await self.config.clock.waitUntilWithSafeContinuity { model.date <= $0 }

			try await self.batchProcessor.add {
				try? await self.config.kafkaService.postTo(topic: .reviewsEvent, message: data);
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
