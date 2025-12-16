// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser;
import Foundation;
import ServiceLifecycle;
import Logging;
import Kafka;

@main
struct yelp_producer: AsyncParsableCommand {
	static let configuration: CommandConfiguration = .init(
		commandName: Bundle.main.executableURL?.lastPathComponent,
		abstract: "Simple temeprature sensor deamon",
	);

	@Option(transform: transformToFileURL)
	var categoryFile: URL;

	@Option(transform: transformToFileURL)
	var stateDirectory: URL;

	@Option(transform: transformToFileURL)
	var sourceDirectory: URL;

	@Option(transform: transformToOrdinaryURL)
	var schemaRegistry: URL;

	@Option(
		name: .customLong("kafka-host"),
		help: "Kafka host to push to. Optionally use host:port to specify the port. Port defaults to 9092.",
		transform: { try transformHostOption($0, defaultPort: 9092) }
	) var kafkaHost: HostSpec;

	mutating func run() async throws {
		try AvroSchemaManager.write(to: stateDirectory, from: BusinessModel.self);
		try AvroSchemaManager.write(to: stateDirectory, from: ReviewModel.self);
		try await AvroSchemaManager.push(to: schemaRegistry, model: ReviewModel.self)
		try await AvroSchemaManager.push(to: schemaRegistry, model: BusinessModel.self)


		let stateManager = try ProducerStateManager(file: self.stateDirectory + StateFileNames.main);
		let processor = try BusinessProcessor(
			stateManager: stateManager,
			sourceFile: self.sourceDirectory + YelpFilenames.businesses,
			cacheFileURL: self.stateDirectory + StateFileNames.processedBusinesses,
			categoryFilterURL: self.categoryFile
		);
		var config: KafkaProducerConfiguration = .init(bootstrapBrokerAddresses: [self.kafkaHost.value])
		config.topicConfiguration.messageTimeout = .timeout(.seconds(3));
		let kafkaService = try KafkaService(config: config, logger: .init(label: "kafka"));

		async let kafkaTask: Void = kafkaService.run();

		try await processor.loadCacheFile();
		try await processor.processFile() { model, data in
			print("hello")
			try await kafkaService.postTo(topic: .BusinessEvents, message: data)
			print("hello")
		}
		print("Businesses \(await processor.dictionary.count)")

		try await kafkaTask;
	}


	mutating func validate() throws {
		guard self.stateDirectory.isDirectory else {
			throw ValidationError("--state-directory must be an existing directory");
		}
	}
}





func saveState(_ state: CancelableFileReading.State) throws {
	let url: URL = URL(fileURLWithPath: "state.json");
	let encoder = JSONEncoder();
	let data = try encoder.encode(state);
	try data.write(to: url);
}

func fetchState() -> CancelableFileReading.State? {
	let url: URL = URL(fileURLWithPath: "state.json");
	guard let data = try? Data(contentsOf: url) else {
		return nil;
	}
	let decoder = JSONDecoder();
	return try? decoder.decode(CancelableFileReading.State.self, from: data);
}
