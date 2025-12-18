import Foundation;
import Kafka;
import ServiceLifecycle;

actor WorldClockWatcher: Service {
	let config: GlobalConfiguration;
	let kafkaConsumer: KafkaConsumer;
	let bootDate: Date = .now;


	init(config: GlobalConfiguration) throws {
		self.config = config;

		var kafkaConfig = KafkaConsumerConfiguration(
			consumptionStrategy: .partition(.init(rawValue: 0), topic: KafkaTopic.worldClock.value),
			bootstrapBrokerAddresses: [config.kafkaHost]
		);
		kafkaConfig.autoOffsetReset = .end;

		self.kafkaConsumer = try KafkaConsumer(configuration: kafkaConfig, logger: config.logger);
	}

	func run() async throws {
		async let task: Void = self.processMessages();
		try await self.kafkaConsumer.run();
		try await task;
	}

	func processMessages() async throws {
		for try await m in self.kafkaConsumer.messages.cancelOnGracefulShutdown().map(Self.parseMessage) {
			print(m);
		}
	}
}

extension WorldClockWatcher {
	private static func parseMessage(_ kafkaMessage: KafkaConsumerMessage) throws -> Time {
		let data = kafkaMessage.value.withUnsafeReadableBytes(Data.init(_:))

		return try Self.Time.decode(fromJSON: data);
	}
}

extension WorldClockWatcher {
	struct Time: Codable {
		private static let jsonDecoder: JSONDecoder = {
			var decoder = JSONDecoder();
			decoder.dateDecodingStrategy = .iso8601;
			return decoder;
		}()
		static func decode(fromJSON data: Data) throws -> Self {
			try Self.jsonDecoder.decode(Self.self, from: data);
		}

		let currentTime: Date;
	}
}
