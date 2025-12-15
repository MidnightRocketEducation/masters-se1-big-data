import Avro;

@AvroSchema
struct BusinessModel: Codable {
	let id: String;
	let name: String;
	let location: Location;
	let stars: Double;
	let categories: [String];

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.name = try container.decode(String.self, forKey: .name)
		self.stars = try container.decode(Double.self, forKey: .stars)

		if let id = try container.decodeIfPresent(String.self, forKey: .id) {
			self.id = id;
			self.categories = try container.decode([String].self, forKey: .categories)
			self.location = try container.decode(Location.self, forKey: .location);
		} else {
			let legacyContainer = try decoder.container(keyedBy: LegacyKeys.self);
			self.id = try legacyContainer.decode(String.self, forKey: .id);
			self.location = try Self.decodeCoordinates(legacyContainer);
			self.categories = try Self.decodeCategories(legacyContainer);
		}
	}

	enum CodingKeys: String, CodingKey {
		case name, stars, categories;
		case id, location;
	}

	/// These cases are used for legacy object decoding
	enum LegacyKeys: String, CodingKey {
		case id = "business_id";
		case longitude, latitude, categories;
	}
}



extension BusinessModel {
	private static func decodeOptionalArray<Element: Decodable, K: CodingKey>(
		_ container: KeyedDecodingContainer<K>,
		forKey key: K
	) throws -> [Element] {
		if try container.decodeNil(forKey: key) {
			return [];
		} else {
			return try container.decode([Element].self, forKey: key);
		}
	}

	private static func decodeCategories(_ container: KeyedDecodingContainer<LegacyKeys>) throws -> [String] {
		if try container.decodeNil(forKey: .categories) {
			return [];
		} else {
			let categoriesString = try container.decode(String.self, forKey: .categories);
			return categoriesString.lowercased().split(separator: ", ").map(String.init);
		}
	}

	private static func decodeCoordinates(_ container: KeyedDecodingContainer<LegacyKeys>) throws -> Location {
		let latitude: Double = try container.decode(Double.self, forKey: .latitude);
		let longitude: Double = try container.decode(Double.self, forKey: .longitude);
		return .init(coordinates: .init(latitude, longitude));
	}
}
