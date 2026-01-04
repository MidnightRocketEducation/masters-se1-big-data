import Foundation;
// https://dev.to/stevenjdh/demystifying-confluents-schema-registry-wire-format-5465
struct ConfluentWireFormat {
	private static let MAGIC_BYTE = Data([0]); // 0x00
	private let header: Data;

	init(id: AvroSchemaManager.RegistryId) {
		var bigEndian = id.id.bigEndian;
		self.header = Self.MAGIC_BYTE + Data(bytes: &bigEndian, count: 4);
	}

	func wrap(data: Data) -> Data {
		return self.header + data;
	}
}
