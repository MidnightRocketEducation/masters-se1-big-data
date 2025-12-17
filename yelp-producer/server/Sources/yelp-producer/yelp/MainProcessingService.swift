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
		
		let businessProcessorComponent = try await BusinessServiceComponent(
			stateManager: stateManager,
			stateDirectory: stateDirectory,
			sourceDirectory: sourceDirectory,
			categoryFile: categoryFile,
			kafkaService: kafkaService,
			logger: logger
		);

		try await withGracefulShutdownHandler {
			try await businessProcessorComponent.run(kafkaService: kafkaService);

		} onGracefulShutdown: {
			Task {
				await businessProcessorComponent.cancel();
			}
		}
	}
}


struct BusinessServiceComponent {
	let processor: BusinessProcessor;
	let batchProcessor: AsyncLimitedBatchProcessor;

	init (
		stateManager: ProducerStateManager,
		stateDirectory: URL,
		sourceDirectory: URL,
		categoryFile: URL,
		kafkaService: KafkaService,
		logger: Logger
	) async throws {
		self.processor = try BusinessProcessor(
			stateManager: stateManager,
			sourceFile: sourceDirectory + YelpFilenames.businesses,
			cacheFileURL: stateDirectory + StateFileNames.processedBusinesses,
			categoryFilterURL: categoryFile
		);
		self.batchProcessor = await AsyncLimitedBatchProcessor(batchSize: 50);
	}

	func run(kafkaService: KafkaService) async throws {
		try await processor.loadCacheFile();
		try await processor.processFile() { model, data in
			try await batchProcessor.add {
				try? await kafkaService.postTo(topic: .BusinessEvents, message: data);
			}
		}
		await batchProcessor.cancel();
		print("Businesses \(await processor.dictionary.count)")
	}

	func cancel() async {
		await self.processor.cancel();
		await self.batchProcessor.cancel();
	}
}
