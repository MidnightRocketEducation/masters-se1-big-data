import Foundation;
import ArgumentParser;

func transformToFileHandle(_ string: String) throws -> FileHandle {
	guard let url = URL(string: string), let fileHandle = try? FileHandle(forReadingFrom: url) else {
		throw ValidationError("Invalid file handle: \(string)");
	}
	return fileHandle;
}

func transformToFileURL(_ string: String) throws -> URL {
	URL(filePath: string);
}
