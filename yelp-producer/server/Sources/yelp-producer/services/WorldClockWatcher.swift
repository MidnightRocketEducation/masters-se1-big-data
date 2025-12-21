import Foundation;
import Kafka;
import ServiceLifecycle;
import CodingKeysGenerator;

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
		self.config.logger.info("Clockwatcher started.")
		try await self.kafkaConsumer.run();
		try await task;
		self.config.logger.info("Clockwatcher existing.")
	}

	func processMessages() async throws {
		for try await m in self.kafkaConsumer.messages.cancelOnGracefulShutdown().map(Self.parseMessage) {
			await config.clock.set(m.current);
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
	@CodingKeys
	struct Time: Codable {
		@CodingKey(custom: "currentTime")
		let current: Date;
	}
}

extension WorldClockWatcher.Time {
	private static let jsonDecoder: JSONDecoder = {
		let decoder = JSONDecoder();
		decoder.dateDecodingStrategy = .iso8601;
		return decoder;
	}();

	static func decode(fromJSON data: Data) throws -> Self {
		try Self.jsonDecoder.decode(Self.self, from: data);
	}
}
