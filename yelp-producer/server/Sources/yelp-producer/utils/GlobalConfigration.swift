import Logging;
import Kafka;

struct GlobalConfiguration {
	let options: Options;
	let logger: Logger;
	let kafkaService: KafkaService;
	let stateManager: ProducerStateManager;
	let clock: ClockContinuity;

	init(options: Options) async throws {
		self.options = options;
		self.stateManager = try ProducerStateManager(file: options.stateDirectory + StateFileNames.main);
		self.logger = Logger(label: "yelp-producer");
		self.clock = ClockContinuity(currentTime: await self.stateManager.get(key: \.clockState));

		var config: KafkaProducerConfiguration = .init(bootstrapBrokerAddresses: [options.kafkaHost.value])
		config.topicConfiguration.messageTimeout = .timeout(.seconds(3));
		self.kafkaService = try KafkaService(config: config, logger: self.logger);
	}
}
