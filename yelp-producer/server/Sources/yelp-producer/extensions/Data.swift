import Foundation;
import Kafka;

extension Data: @retroactive KafkaContiguousBytes {
}

extension Data {
	func hexEncodedString(uppercase: Bool = false) -> String {
		let format = "%02\(uppercase ? "X" : "x")";
		return self.reduce(into: "") { $0.append(String(format: format, $1)) }
	}
}
