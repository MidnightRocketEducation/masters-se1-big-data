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

		if self.config.options.resetFutureReviewsOnBrokenContinuity {
			try await self.processFutureReviewWithRestartOnBrokenContinuity(businesses: businessDict);
		} else {
			try await self.processFutureReview(businesses: businessDict);
		}
	}

	func processFutureReviewWithRestartOnBrokenContinuity(businesses: [String: BusinessModel]) async throws {
		while true {
			do {
				try await self.processFutureReview(businesses: businesses);
				return;
			} catch let error as ClockContinuity.Error {
				guard case .brokenContinuity = error else {
					throw error;
				}
				self.config.logger.info("Broken continuity. Reseting progress of future reviews.");
				await self.config.clock.clearContinuity();
				try await self.config.stateManager.update(key: \.clockState, to: .distantPast);
				try await self.config.stateManager.update(key: \.reviewsFileStateFuture, to: .new);
			}
		}
	}

	func processFutureReview(businesses: [String: BusinessModel]) async throws {
		let reviewFutureServiceComponent = try await ReviewFutureServiceComponent(config: self.config, businesses: businesses);
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
