import Foundation;
extension URL {
	static func + (lhs: URL, rhs: any RawRepresentable<String>) -> URL {
		lhs.appending(path: rhs.rawValue);
	}
}


// Source - https://stackoverflow.com/a/65152079
// Posted by Leo Dabus, modified by community. See post 'Timeline' for change history
// Retrieved 2025-12-15, License - CC BY-SA 4.0
extension URL {
	var isDirectory: Bool {
		(try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false;
	}
}
