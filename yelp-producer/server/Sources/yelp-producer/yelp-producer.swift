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

	@Option(transform: transformToURL)
	var sourceDirectory: URL;

	mutating func run() async throws {
		let categoryFilter = try await CategoryFilter.load(from: categoryFile);
		let jsonDecoder = JSONDecoder();
		jsonDecoder.dateDecodingStrategy = .formatted(ReviewModel.dateFormatter);
		// let jsonEncoder = JSONEncoder();

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
		print("Done import businesses");
		let reviewsFile = self.sourceDirectory.appending(path: "yelp_academic_dataset_review.json");
		var reviews: [ReviewModel] = [];
		for try await line in AsyncLineSequenceFromFile(from: try .init(forReadingFrom: reviewsFile)) {
			do {
				let obj = try jsonDecoder.decode(ReviewModel.self, from: Data(line.utf8));
				if businessDictionary[obj.businessId] != nil {
					//print(ReviewModel.dateFormatter.string(from: obj.date));
					reviews.append(obj);
				}
			} catch {
				print();
				print("Failed to decode:\n\(line)");
				print();
				throw error;
			}
		}

		print(businessDictionary.count);
		print(reviews.count);
		try await Task.sleep(for: .seconds(3));
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
