import Foundation;

public actor AtomicFileWriter {
	private let fileHandle: FileHandle;
	private let targetPath: URL;
	private let tempFileURL: URL;

	private init(path: URL) throws {
		self.targetPath = path;
		self.tempFileURL = Self.getTempFileURL(for: path);
		_ = FileManager.default.createFile(atPath: tempFileURL.path(), contents: nil);
		self.fileHandle = try FileHandle(forWritingTo: tempFileURL);
	}

	private init(forAppendingTo path: URL) throws {
		self.targetPath = path;
		self.tempFileURL = Self.getTempFileURL(for: path);
		if FileManager.default.fileExists(atPath: path.path()) {
			_ = try FileManager.default.copyItem(at: path, to: tempFileURL);
		} else {
			_ = FileManager.default.createFile(atPath: tempFileURL.path(), contents: nil);
		}
		self.fileHandle = try FileHandle(forWritingTo: tempFileURL);
		try self.fileHandle.seekToEnd();
	}

	public func write(data: Data) throws {
		try self.fileHandle.write(contentsOf: data);
	}

	public func write(string: String) throws {
		try self.write(data: Data(string.utf8));
	}

	public func flush() throws {
		try self.fileHandle.synchronize();
		let newTmpPath = Self.getTempFileURL(for: self.targetPath);
		try FileManager.default.copyItem(at: self.tempFileURL, to: newTmpPath);
		_ = try FileManager.default.replaceItemAt(self.targetPath, withItemAt: newTmpPath);
	}

	private func commit() throws {
		try self.fileHandle.synchronize();
		try self.fileHandle.close();
		let _ = try FileManager.default.replaceItemAt(self.targetPath, withItemAt: self.tempFileURL);
	}

	private nonisolated func cleanup() {
		try? FileManager.default.removeItem(at: self.tempFileURL);
	}
}

extension AtomicFileWriter {
	public static func write(to path: URL, mode: Mode = .overwrite, dataProvider: @Sendable (AtomicFileWriter) async throws -> Void) async throws {
		let writer = switch(mode) {
			case .overwrite: try AtomicFileWriter(path: path);
			case .append: try AtomicFileWriter(forAppendingTo: path);
		}
		defer {
			writer.cleanup();
		}
		try await dataProvider(writer);
		try await writer.commit();
	}
}
extension AtomicFileWriter {
	private static func getTempFileURL(for url: URL) -> URL {
		url.appendingPathExtension("\(Self.genRandomName(6)).tmp");
	}
	// https://github.com/openbsd/src/blob/fafc58a366561ab932cd83a63915a6bbddd0d112/lib/libc/stdlib/__mktemp4.c#L24
	private static let CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
	private static func genRandomName(_ length: Int) -> String {
		var out = "";
		out.reserveCapacity(length);

		while out.count < length {
			out.append(Self.CHARS.randomElement()!);
		}
		return out;
	}
}

extension AtomicFileWriter {
	public enum Mode {
		case overwrite;
		case append;
	}
}
