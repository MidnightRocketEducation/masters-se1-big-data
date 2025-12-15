import Kafka;
import ServiceLifecycle;
import Logging;

actor KafkaService: Service {
	let producer: KafkaProducer;
	let events: KafkaProducerEvents;
	var continuations: [KafkaProducerMessageID: CheckedContinuation<Void, Never>] = [:];

	init(config: KafkaProducerConfiguration, logger: Logger) throws {
		(self.producer, self.events) = try KafkaProducer.makeProducerWithEvents(configuration: config, logger: logger);
	}

	func run() async throws {
		try await withGracefulShutdownHandler {
			async let handleEventsTask: Void = self.handleEvents();

			try await self.producer.run();

			await handleEventsTask;
		} onGracefulShutdown: {
			self.producer.triggerGracefulShutdown();
		}
	}

	func postTo(topic: String, message: String) async throws -> Void {
		let messageId: KafkaProducerMessageID = try producer.send(KafkaProducerMessage(topic: topic, value: message));
		await withCheckedContinuation { continuation in
			self.continuations[messageId] = continuation;
		}
	}

	private func handleEvents() async {
		for await event in events {
			switch event {
			case .deliveryReports(let deliveryReports):
				for deliveryReport in deliveryReports {
					if let continuation = self.continuations.removeValue(forKey: deliveryReport.id) {
						continuation.resume();
					}
				}
			default:
				break
			}
		}
	}
}

enum KafkaTopics: String {
	case BusinessEvents = "business-events";
	case ReviewsEvent = "reviews-event";
}
