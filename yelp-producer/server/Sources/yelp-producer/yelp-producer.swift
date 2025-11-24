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
		SignalHandler.register(.INT, .TERM) { sig in
			print("Got signal: \(sig)\nExiting...");
			return .ok;
		}
		print(getpid());
		try await Task.sleep(for: .seconds(10))

		var rafr = ResumeableAsyncFileReading(fileHandle: file);
		for try await s in try rafr.resume(state: .init(byteOffset: 0, lineOffset: 20)) {
			print("\(try file.offset()):  \(s)");
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
