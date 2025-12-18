import Logging;
import Kafka;

struct GlobalConfiguration {
	let options: Options;
	let stateManager: ProducerStateManager;
	let clock: ClockContinuity;
	let logger: Logger;
	let kafkaProducerService: KafkaProducerService;
	let kafkaHost: KafkaConfiguration.BrokerAddress;

	init(options: Options) async throws {
		self.options = options;
		self.stateManager = try ProducerStateManager(file: options.stateDirectory + StateFileNames.main);
		self.logger = Logger(label: "yelp-producer");
		self.clock = ClockContinuity(currentTime: await self.stateManager.get(key: \.clockState));

		self.kafkaHost = options.kafkaHost.value;


		var config: KafkaProducerConfiguration = .init(bootstrapBrokerAddresses: [kafkaHost])
		config.topicConfiguration.messageTimeout = .timeout(.seconds(3));
		self.kafkaProducerService = try KafkaProducerService(config: config, logger: self.logger);
	}
}
