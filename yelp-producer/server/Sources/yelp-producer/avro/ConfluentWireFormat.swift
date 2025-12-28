import Foundation;
// https://dev.to/stevenjdh/demystifying-confluents-schema-registry-wire-format-5465
struct ConfluentWireFormat {
	private let magicBytes: Data;

	init(id: AvroSchemaManager.RegistryId) {
		var bigEndian = id.id.bigEndian;
		self.magicBytes = Data([0]) + Data(bytes: &bigEndian, count: 4);
	}

	func wrap(data: Data) -> Data {
		return self.magicBytes + data;
	}
}
