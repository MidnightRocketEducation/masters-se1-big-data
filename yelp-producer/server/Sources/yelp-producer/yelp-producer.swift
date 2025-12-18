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

		if !(await config.stateManager.get(key: \.hasUploadedSchema)) {
			try AvroSchemaManager.write(to: config.options.stateDirectory, from: BusinessModel.self);
			try AvroSchemaManager.write(to: config.options.stateDirectory, from: ReviewModel.self);
			try await AvroSchemaManager.push(to: config.options.schemaRegistry, model: ReviewModel.self)
			try await AvroSchemaManager.push(to: config.options.schemaRegistry, model: BusinessModel.self)
			try await config.stateManager.update(key: \.hasUploadedSchema, to: true)
		}



		let mainProcessor = MainProcessingService(config: config);

		let serviceGroup = ServiceGroup(
			services: [config.kafkaService, mainProcessor],
			gracefulShutdownSignals: [.sighup, .sigterm, .sigint, .sigpipe],
			logger: config.logger
		);


		async let serviceTask: Void = serviceGroup.run();


		try await serviceTask;
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
