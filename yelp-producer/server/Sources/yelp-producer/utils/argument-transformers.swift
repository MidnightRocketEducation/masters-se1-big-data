import Foundation;
import ArgumentParser;
import Kafka;

func transformToFileHandle(_ string: String) throws -> FileHandle {
	guard let url = URL(string: string), let fileHandle = try? FileHandle(forReadingFrom: url) else {
		throw ValidationError("Invalid file handle: \(string)");
	}
	return fileHandle;
}

func transformToFileURL(_ string: String) throws -> URL {
	URL(filePath: string);
}


func transformHostOption(_ string: String, defaultPort: Int) throws -> HostSpec {
	guard let host = string.prefixMatch(of: /^[^:\/\s]*(?=$|:\d*$)/) else {
		throw ValidationError("Invalid host spec: \(string)");
	}

	guard let port = string.firstMatch(of: /:(\d*)/) else {
		return HostSpec(host: String(host.output), port: defaultPort);
	}

	guard let portNumber = Int(port.1) else {
		throw ValidationError("Invalid port spec: \(string)");
	}

	return HostSpec(host: String(host.output), port: portNumber);
}

struct HostSpec {
	let host: String;
	let port: Int;

	var value: KafkaConfiguration.BrokerAddress {
		.init(host: self.host, port: self.port)
	}
}
