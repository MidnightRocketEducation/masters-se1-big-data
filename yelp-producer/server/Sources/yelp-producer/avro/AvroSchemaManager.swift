import Avro;
import Foundation;
import CodingKeysGenerator;

struct AvroSchemaManager {
	static let jsonEncoder: JSONEncoder = {
		let jsonEncoder = JSONEncoder();
		jsonEncoder.outputFormatting = .sortedKeys;
		return jsonEncoder;
	}();
	static let jsonDecoder: JSONDecoder = JSONDecoder();

	static func generate(from model: AvroProtocol.Type) throws -> Data {
		return try jsonEncoder.encode(model.avroSchema);
	}

	static func write(to url: URL, from model: AvroProtocol.Type) throws {
		let url = url.isDirectory ? url.appending(path: "\(model).avsc") : url;

		try generate(from: model).write(to: url);
	}
}

extension AvroSchemaManager {
	/**
	 Returns a boolean indicating whether or not the schema was updated
	 */
	@discardableResult
	static func push(to baseURL: URL, model: AvroProtocol.Type, subject: KafkaTopic) async throws -> Bool {
		let subjectURL = baseURL.appending(components: "subjects", subject.schemaSubject, "versions");

		try await WebClient.post(
			url: subjectURL,
			body: try RegistrySchema(from: model).toJSON(),
			contentType: .confluentSchema
		);
		return true;
	}

	static func get(from baseURL: URL, model: AvroProtocol.Type, subject: String? = nil) async throws -> AvroSchemaDefinition? {
		let subjectURL = baseURL.appending(components: "subjects", subject ?? "\(model)-avsc", "versions", "latest");
		let data = try await WebClient.run(url: subjectURL);
		do {
			let rs = try jsonDecoder.decode(RegistrySchema.self, from: data);
			return try jsonDecoder.decode(AvroSchemaDefinition.self, from: Data(rs.schema.utf8));
		} catch _ as DecodingError {
			let err = try jsonDecoder.decode(RegistryErrorMessage.self, from: data);
			if err.errorCode == 40401 {
				return nil
			}
			throw err;
		}
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

	@CodingKeys
	struct RegistryErrorMessage: Codable, Swift.Error {
		let message: String;
		let errorCode: Int;
	}

	enum Error: Swift.Error {
		case invalidEncoding;
	}
}
