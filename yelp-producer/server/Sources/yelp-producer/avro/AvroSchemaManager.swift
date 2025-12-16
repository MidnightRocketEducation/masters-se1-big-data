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
	static func push(to baseUrl: URL, model: AvroProtocol.Type, subject: String? = nil) async throws {
		let url = baseUrl.appending(components: "subjects", subject ?? "\(model)-avsc", "versions");
		try await WebClient.post(
			url: url,
			body: try RegistrySchema(from: model).toJSON(),
			contentType: .confluentSchema
		);
	}

	struct RegistrySchema: Codable {
		let schema: String;

		init(schema: AvroSchemaDefinition) throws {
			guard let schema = String(data: try jsonEncoder.encode(schema), encoding: .utf8) else {
				throw Error.invalidEncoding;
			}
			self.schema = schema;
		}

		init(from model: AvroProtocol.Type) throws {
			try self.init(schema: model.avroSchema);
		}

		func toJSON() throws -> Data {
			try jsonEncoder.encode(self);
		}
	}

	enum Error: Swift.Error {
		case invalidEncoding;
	}
}
