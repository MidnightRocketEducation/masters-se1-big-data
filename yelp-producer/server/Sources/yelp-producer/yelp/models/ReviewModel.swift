import Foundation;
import CodingKeysGenerator;
import Avro;

@CodingKeys
@AvroSchema
struct ReviewModel: Codable {
	@CodingKey(custom: "review_id")
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
