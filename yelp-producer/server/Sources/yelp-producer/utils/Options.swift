import ArgumentParser;
import Foundation;

struct Options: ParsableArguments {
	@Option(transform: transformToFileURL)
	var categoryFile: URL;

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

	func validate() throws {
		guard self.stateDirectory.isDirectory else {
			throw ValidationError("--state-directory must be an existing directory");
		}
	}
}
