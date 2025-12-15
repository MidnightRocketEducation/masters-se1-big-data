import Avro;
import Foundation;

struct AvroSchemaManager {
	static let jsonEncoder = JSONEncoder();
	static func generate(from model: AvroProtocol.Type) throws -> Data {
		return try jsonEncoder.encode(model.avroSchema);
	}

	static func write(to url: URL, from model: AvroProtocol.Type) throws {
		let url = url.isDirectory ? url.appending(path: "\(model).avsc") : url;

		try generate(from: model).write(to: url);
	}
}
