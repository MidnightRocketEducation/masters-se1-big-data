import Logging;
import Kafka;

struct GlobalConfiguration {
	let options: Options;
	let logger: Logger;
	let kafkaService: KafkaService;
	let stateManager: ProducerStateManager;

	init(options: Options) throws {
		self.options = options;
		self.stateManager = try ProducerStateManager(file: options.stateDirectory + StateFileNames.main);
		self.logger = Logger(label: "yelp-producer");

		var config: KafkaProducerConfiguration = .init(bootstrapBrokerAddresses: [options.kafkaHost.value])
		config.topicConfiguration.messageTimeout = .timeout(.seconds(3));
		self.kafkaService = try KafkaService(config: config, logger: self.logger);
	}
}
