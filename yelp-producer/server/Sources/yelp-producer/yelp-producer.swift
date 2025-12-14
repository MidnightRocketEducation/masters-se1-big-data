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

	@Option(transform: transformToFileURL)
	var stateDirectory: URL;

	@Option(transform: transformToFileURL)
	var sourceDirectory: URL;

	mutating func run() async throws {
		let categoryFilter = try await CategoryFilter.load(from: categoryFile);
		let jsonDecoder = JSONDecoder();
		jsonDecoder.dateDecodingStrategy = .formatted(ReviewModel.dateFormatter);
		// let jsonEncoder = JSONEncoder();

		/*
		var businessDictionary: [String: BusinessModel] = [:];
		let businessFile = sourceDirectory.appending(path: "yelp_academic_dataset_business.json");
		for try await line in AsyncLineSequenceFromFile(from: try .init(forReadingFrom: businessFile)) {
			do {
				let obj = try jsonDecoder.decode(BusinessModel.self, from: Data(line.utf8));
				if categoryFilter.matches(categoryArray: obj.categories) {
					businessDictionary[obj.id] = obj;
				}
			} catch {
				print();
				print("Failed to decode:\n\(line)");
				print();
				throw error;
			}
		}
		print("Done import businesses: \(businessDictionary.count)");
		let reviewsFile = self.sourceDirectory.appending(path: "sorted/yelp_academic_dataset_review.json");
		var reviews: [ReviewModel] = [];
		let reader = CancelableFileReading(file: try .init(forReadingFrom: reviewsFile), state: fetchState() ?? .new);
		SignalHandler.register(.INT, .TERM, .PIPE) { _ in
			await reader.cancel();
			try? await Task.sleep(for: .seconds(5));
			return .intrrupted;
		}

		do {
			let state = try await reader.read { line in
				let obj = try jsonDecoder.decode(ReviewModel.self, from: Data(line.utf8));
				if businessDictionary[obj.businessId] != nil {
					if let prevDate = reviews.last?.date, prevDate > obj.date {
						print("Wrong date order")
						await reader.cancel();
					}
					reviews.append(obj);
				}
			}
		} catch {
			switch error {
			case .cancelled(let state):
				try saveState(state);
			case .readerError(let e, let state):
				try saveState(state);
				throw e;
			}
		}

		print("Done import reviews: \(reviews.count)");
		print("Done sort");

		try await Task.sleep(for: .seconds(3));
		 */


		let stateManager = ProducerStateManager.empty;
		try await stateManager.update(key: \.reviewsFileState, to: .new);

		try await AtomicFileWriter.write(to: self.stateDirectory.appending(path: "test.state"), mode: .append) { writer in
			try writer.write(string: "hello");
			// try await Task.sleep(for: .seconds(1))
		}
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
