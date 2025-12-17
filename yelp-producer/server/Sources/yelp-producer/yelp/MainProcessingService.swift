import Foundation;
import ServiceLifecycle;
import Logging;

actor MainProcessingService: Service {
	let config: GlobalConfiguration;

	init(config: GlobalConfiguration) {
		self.config = config;
	}

	func run() async throws {
		
		let businessProcessorComponent = try await BusinessServiceComponent(config: config);

		try await withGracefulShutdownHandler {
			try await businessProcessorComponent.run(kafkaService: config.kafkaService);

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

	init (config: GlobalConfiguration) async throws {
		self.processor = try BusinessProcessor(config: config);
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
