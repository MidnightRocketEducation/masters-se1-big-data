import ArgumentParser;
import Foundation;

struct Options: ParsableArguments {
	@Option(transform: transformToFileURL)
	var categoryFile: URL = URL(filePath: "/usr/local/lib/yp-daemon/categories");

	@Option(transform: transformToFileURL)
	var stateDirectory: URL;

	@Option(transform: transformToFileURL)
	var sourceDirectory: URL;

	@Option(transform: transformToOrdinaryURL)
	var schemaRegistry: URL;

	@Option(
		help: "Kafka host to push to. Optionally use host:port to specify the port. Port defaults to 9092.",
		transform: { try transformHostOption($0, defaultPort: 9092) }
	) var kafkaHost: HostSpec;

	@Flag(inversion: .prefixedNo)
	var resetFutureReviewsOnBrokenContinuity: Bool = true;

	@Option(help: "The minimum number of categories from the categories file, which businesses should have.")
	var businessCategoriesFilterThreshold: Int = 3;

	func validate() throws {
		guard self.stateDirectory.isDirectory else {
			throw ValidationError("--state-directory must be an existing directory");
		}

		guard FileManager.default.isReadableFile(atPath: self.categoryFile.path()) else {
			throw ValidationError("Cannot read file at \(self.categoryFile.path())");
		}
	}
}
