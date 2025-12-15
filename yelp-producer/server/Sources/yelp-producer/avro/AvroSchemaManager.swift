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

extension AvroSchemaManager {
	static func push(to url: URL, model: AvroProtocol.Type) async throws {
		try await WebClient.post(
			url: url,
			body: try RegistrySchema(from: model).toJSON(),
			contentType: .confluentSchema
		);
	}

	struct RegistrySchema: Codable {
		let schema: AvroSchemaDefinition;

		init(schema: AvroSchemaDefinition) {
			self.schema = schema;
		}

		init(from model: AvroProtocol.Type) throws {
			self.init(schema: model.avroSchema);
		}

		func toJSON() throws -> Data {
			try jsonEncoder.encode(self);
		}
	}
}
