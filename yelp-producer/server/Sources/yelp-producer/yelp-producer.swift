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

	@OptionGroup
	var options: Options;



	mutating func run() async throws {
		let config = try await GlobalConfiguration(options: self.options);


		for (p, c) in YelpFilenames.allCases.map({ (config.options.sourceDirectory + $0, $0)}) {
			guard FileManager.default.fileExists(atPath: p.path()) else {
				throw ValidationError("Source directory does not contain \(c)");
			}
		}

		if await config.stateManager.get(key: \.businessSchemaID) == nil {
			config.logger.info("Generates avro schema files for review");
			try AvroSchemaManager.write(to: config.options.stateDirectory, from: BusinessModel.self);
			config.logger.info("Pushing avro schema files to registry at: \(config.options.schemaRegistry.absoluteString)");
			let businessSchemaID = try await AvroSchemaManager.push(to: config.options.schemaRegistry, model: BusinessModel.self, subject: .businessEvent);
			try await config.stateManager.update(key: \.businessSchemaID, to: businessSchemaID);
		}

		if await config.stateManager.get(key: \.reviewSchemaID) == nil {
			config.logger.info("Generates avro schema files for business");
			try AvroSchemaManager.write(to: config.options.stateDirectory, from: ReviewModel.self);
			config.logger.info("Pushing avro schema files to registry at: \(config.options.schemaRegistry.absoluteString)");
			let reviewSchemaID = try await AvroSchemaManager.push(to: config.options.schemaRegistry, model: ReviewModel.self, subject: .reviewEvent);
			try await config.stateManager.update(key: \.reviewSchemaID, to: reviewSchemaID);
		}



		let mainProcessor = MainProcessingService(config: config);
		let clockWatcher = try WorldClockWatcher(config: config);

		let serviceGroup = ServiceGroup(
			services: [
				config.kafkaProducerService,
				clockWatcher,
				mainProcessor,
			],
			gracefulShutdownSignals: [.sighup, .sigterm, .sigint, .sigpipe],
			logger: config.logger
		);


		try await serviceGroup.run();
		config.logger.info("Exiting.");
	}


	func validate() throws {
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
