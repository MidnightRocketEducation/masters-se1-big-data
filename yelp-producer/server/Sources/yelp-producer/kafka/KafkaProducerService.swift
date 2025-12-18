import Kafka;
import Foundation;
import ServiceLifecycle;
import Logging;

actor KafkaProducerService: Service {
	let producer: KafkaProducer;
	let events: KafkaProducerEvents;
	var continuations: [KafkaProducerMessageID: CheckedContinuation<Void, any Swift.Error>] = [:];

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

	func postTo(topic: KafkaTopic, message: Data) async throws -> Void {
		let messageId: KafkaProducerMessageID = try producer.send(KafkaProducerMessage(topic: topic.value, value: message));
		try await withCheckedThrowingContinuation { continuation in
			self.continuations[messageId] = continuation;
		}
	}

	private func handleEvents() async {
		for await event in events.cancelOnGracefulShutdown() {
			guard case let .deliveryReports(deliveryReports) = event else {
				assert(false, "Unhandled event: \(event)");
				continue;
			}
			for deliveryReport in deliveryReports {
				if let continuation = self.continuations.removeValue(forKey: deliveryReport.id) {
					if case .failure(let error) = deliveryReport.status {
						continuation.resume(throwing: error);
					} else {
						continuation.resume();
					}
				}
			}
		}
		self.continuations.forEach {$0.value.resume(throwing: Error.kafkaServiceStopped)}
		self.continuations.removeAll();
	}
}

extension KafkaProducerService {
	enum Error: Swift.Error {
		case kafkaServiceStopped;
	}
}

enum KafkaTopic: String {
	case businessEvent = "business-event";
	case reviewsEvent = "reviews-event";
	case worldClock = "world-clock";

	var value: RawValue {
		#if KAFKA_DEBUG_TOPIC
		"debug-" + rawValue
		#else
		rawValue
		#endif
	}
}
