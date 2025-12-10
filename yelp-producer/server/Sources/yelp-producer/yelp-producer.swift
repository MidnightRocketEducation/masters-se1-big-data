// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser;
import Foundation;
import ServiceLifecycle;

@main
struct yelp_producer: AsyncParsableCommand {
	static let configuration: CommandConfiguration = .init(
		commandName: Bundle.main.executableURL?.lastPathComponent,
		abstract: "Simple temeprature sensor deamon",
	);

	@Option(transform: transformToFileHandle)
	var categoryFile: FileHandle;

	@Option(transform: transformToURL)
	var stateDirectory: URL;

	mutating func run() async throws {
		let asyncReader = CancelableFileReading(file: categoryFile);
		let set: AsyncSet<String> = .init();
		let _ = try await asyncReader.read {
			await set.insert($0);
		}
		print(await set.description);
	}


	mutating func validate() throws {
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
