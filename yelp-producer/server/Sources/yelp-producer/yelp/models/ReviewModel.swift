import Foundation;
import CodingKeysGenerator;
import Avro;

@AvroSchema
struct ReviewModel: Codable {
	let id: String;
	let businessId: String;
	let stars: Double;
	@LogicalType(.timestampMillis)
	let date: Date;
}


extension ReviewModel: Comparable {
	static func < (lhs: ReviewModel, rhs: ReviewModel) -> Bool {
		if lhs.date == rhs.date {
			return lhs.id < rhs.id;
		}
		return lhs.date < rhs.date;
	}
}

extension ReviewModel {
	init(from decoder: some Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self);
		self.stars = try container.decode(Double.self, forKey: .stars);
		if let id = try container.decodeIfPresent(String.self, forKey: .id) {
			self.id = id;
			self.businessId = try container.decode(String.self, forKey: .businessId);
			self.date = try container.decode(Date.self, forKey: .date);
		} else {
			let legacyContainer = try decoder.container(keyedBy: LegacyKeys.self);
			self.id = try legacyContainer.decode(String.self, forKey: .id);
			self.businessId = try legacyContainer.decode(String.self, forKey: .businessId);
			self.date = try legacyContainer.decode(Date.self, forKey: .date);
		}
	}

	enum CodingKeys: String, CodingKey {
		case id;
		case businessId;
		case stars;
		case date = "recordDate";
	}

	enum LegacyKeys: String, CodingKey {
		case id = "review_id";
		case businessId = "business_id";
		case date;
	}

	static let dateFormatter: DateFormatter = {
		let formatter = DateFormatter();
		formatter.dateFormat = "yyyy-MM-dd HH:mm:ss";
		formatter.timeZone = TimeZone(abbreviation: "UTC");
		return formatter;
	}();

	static let jsonDecoder: JSONDecoder = {
		let decoder = JSONDecoder();
		decoder.dateDecodingStrategy = .formatted(dateFormatter);
		return decoder;
	}();

	static let jsonEncoder: JSONEncoder = {
		let encoder = JSONEncoder();
		encoder.dateEncodingStrategy = .iso8601;
		return encoder;
	}();
}
