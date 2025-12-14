import Foundation;
import CodingKeysGenerator;

@CodingKeys
struct ReviewModel: Codable {
	@CodingKey(custom: "review_id")
	let id: String;
	let businessId: String;
	let stars: Double;
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
}
