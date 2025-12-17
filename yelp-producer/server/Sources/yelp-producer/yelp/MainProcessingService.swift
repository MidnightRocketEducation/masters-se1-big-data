import Foundation;
import ServiceLifecycle;
import Logging;

actor MainProcessingService: Service {
	let stateManager: ProducerStateManager;
	let stateDirectory: URL;
	let sourceDirectory: URL;
	let categoryFile: URL;
	let kafkaService: KafkaService;
	let logger: Logger;

	init(stateManager: ProducerStateManager, stateDirectory: URL, sourceDirectory: URL, categoryFile: URL, kafkaService: KafkaService, logger: Logger) {
		self.stateManager = stateManager;
		self.stateDirectory = stateDirectory;
		self.sourceDirectory = sourceDirectory;
		self.categoryFile = categoryFile;
		self.kafkaService = kafkaService;
		self.logger = logger;
	}

	func run() async throws {
		
		let processor = try BusinessProcessor(
			stateManager: stateManager,
			sourceFile: self.sourceDirectory + YelpFilenames.businesses,
			cacheFileURL: self.stateDirectory + StateFileNames.processedBusinesses,
			categoryFilterURL: self.categoryFile
		);
		let batchProcessor = await AsyncLimitedBatchProcessor(batchSize: 50);

		try await withGracefulShutdownHandler {

			try await processor.loadCacheFile();
			try await processor.processFile() { model, data in
				try await batchProcessor.add {
					try? await self.kafkaService.postTo(topic: .BusinessEvents, message: data);
				}
			}
			await batchProcessor.cancel();
			print("Businesses \(await processor.dictionary.count)")
		} onGracefulShutdown: {
			Task {
				await processor.cancel();
				await batchProcessor.cancel();
			}
		}
	}
}
