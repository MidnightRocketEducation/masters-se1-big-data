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

		let businessDict = try await withGracefulShutdownHandler {
			try await businessProcessorComponent.run();
		} onGracefulShutdown: {
			Task {
				await businessProcessorComponent.cancel();
			}
		}

		let reviewPastServiceComponent = try await ReviewPastServiceComponent(config: config, businesses: businessDict);
		try await withGracefulShutdownHandler {
			try await reviewPastServiceComponent.run();
			config.logger.info("Done import reviews.past");
		} onGracefulShutdown: {
			Task {
				await reviewPastServiceComponent.cancel();
			}
		}

	}
}


