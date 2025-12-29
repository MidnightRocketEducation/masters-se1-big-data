#if os(Linux)
import Foundation;
extension FileManager {
	func replaceItemAt(_ path: URL, withItemAt newPath: URL) throws {
		try? self.removeItem(at: path);
		try self.moveItem(at: newPath, to: path);
	}
}
#endif // os(Linux)
