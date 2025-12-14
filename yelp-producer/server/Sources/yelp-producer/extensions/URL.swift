import Foundation;
extension URL {
	static func + (lhs: URL, rhs: any RawRepresentable<String>) -> URL {
		lhs.appending(path: rhs.rawValue);
	}
}
