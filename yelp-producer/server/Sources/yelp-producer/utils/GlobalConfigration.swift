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
		self.logger = Logger(label: "yelp-producer");
		self.options = options;

		#if DEBUG
		self.logger.info("Compiled in Debug mode. Using debug configurations.")
		#else
		self.logger.info("Compiled in Release mode. Using production configurations.")
		#endif

		self.logger.info("Loading state");
		self.stateManager = try ProducerStateManager(file: options.stateDirectory + StateFileNames.main);
		self.logger.info("Done loading state");
		self.clock = ClockContinuity(currentTime: await self.stateManager.get(key: \.clockState));

		self.kafkaHost = options.kafkaHost.value;


		var config: KafkaProducerConfiguration = .init(bootstrapBrokerAddresses: [kafkaHost])
		config.topicConfiguration.messageTimeout = .timeout(.seconds(3));
		self.kafkaProducerService = try KafkaProducerService(config: config, logger: self.logger);
	}
}
