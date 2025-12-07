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
		let cancelableReader = CancelableFileReading(file: file, state: fetchState() ?? .new);

		SignalHandler.register(.INT, .TERM, .PIPE) { sig in
			stderr("Got signal: \(sig)\nExiting...");
			await cancelableReader.cancel();
			return .ok;
		}

		do {
			let state = try await cancelableReader.read() { line in
				print(line);
			}
			try saveState(state);
		} catch let e as CancelableFileReading.Error {
			switch e {
			case .readerError(_, let state):
				try saveState(state);
				fallthrough;
			default:
				throw e;
			}
		}
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
