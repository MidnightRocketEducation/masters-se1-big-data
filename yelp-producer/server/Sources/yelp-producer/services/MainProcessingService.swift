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

		let businessDict = try await withTaskCancellationOrGracefulShutdownHandler {
			try await businessProcessorComponent.run();
		} onCancelOrGracefulShutdown: {
			self.config.logger.info("Recieved interrupt")
			Task {
				await businessProcessorComponent.cancel();
			}
		}

		let reviewPastServiceComponent = try await ReviewPastServiceComponent(config: config, businesses: businessDict);
		try await withTaskCancellationOrGracefulShutdownHandler {
			try await reviewPastServiceComponent.run();
			config.logger.info("Done import reviews.past");
		} onCancelOrGracefulShutdown: {
			self.config.logger.info("Recieved interrupt")
			Task {
				await reviewPastServiceComponent.cancel();
			}
		}

		let reviewFutureServiceComponent = try await ReviewFutureServiceComponent(config: config, businesses: businessDict);
		try await withTaskCancellationOrGracefulShutdownHandler {
			try await reviewFutureServiceComponent.run();
		} onCancelOrGracefulShutdown: {
			self.config.logger.info("Recieved interrupt")
			Task {
				await reviewFutureServiceComponent.cancel();
			}
		}
	}
}


