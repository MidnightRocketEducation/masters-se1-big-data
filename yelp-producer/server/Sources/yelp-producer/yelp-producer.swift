// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser;
import Foundation;

@main
struct yelp_producer: AsyncParsableCommand {
	static let configuration: CommandConfiguration = .init(
		commandName: Bundle.main.executableURL?.lastPathComponent,
		abstract: "Simple temeprature sensor deamon",
	);

	@Argument(transform: parseFileHandle)
	var file: FileHandle;

	mutating func run() async throws {
		let file = self.file;
		let task = Task {
			let rafr = ResumeableAsyncFileReading(fileHandle: file);
			for try await s in try rafr.resume(from: fetchState() ?? .beginning) {
				print("\(try file.offset()):  \(s)");
				if Task.isCancelled {
					print("Saving state");
					try saveState(s.state);
					return;
				}
			}
		}

		SignalHandler.register(.INT, .TERM, .PIPE) { sig in
			stderr("Got signal: \(sig)\nExiting...");
			task.cancel();
			let _ = await task.result;
			return .ok;
		}

		let _ = await task.result;
	}


	mutating func validate() throws {
	}
}

func parseFileHandle(_ string: String) throws -> FileHandle {
	guard let url = URL(string: string), let fileHandle = try? FileHandle(forReadingFrom: url) else {
		throw ValidationError("Invalid file handle: \(string)")
	}
	return fileHandle
}

func saveState(_ state: FileReadingState) throws {
	let url: URL = URL(fileURLWithPath: "state.json");
	let encoder = JSONEncoder();
	let data = try encoder.encode(state);
	try data.write(to: url);
}

func fetchState() -> FileReadingState? {
	let url: URL = URL(fileURLWithPath: "state.json");
	guard let data = try? Data(contentsOf: url) else {
		return nil;
	}
	let decoder = JSONDecoder();
	return try? decoder.decode(FileReadingState.self, from: data);
}
