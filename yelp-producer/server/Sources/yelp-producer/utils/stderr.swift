import class Foundation.FileHandle;
import struct Foundation.Data;
import func Foundation.isatty;

// https://stackoverflow.com/a/41679101
extension FileHandle: @retroactive TextOutputStream {
	public func write(_ str: String) {
		self.write(Data(str.utf8));
	}
}
// https://forums.swift.org/t/rework-print-by-adding-observable-standardoutput-and-standarderror-streams-to-standard-library/7775/12
func stderr(_ inputs: Any..., separator: String = " ", terminator: String = "\n") -> Void {
	// FileHandle.standardError.write(inputs.map{String(describing: $0)}.joined(separator: separator) + terminator);
	var stderr = FileHandle.standardError;
	print(inputs, separator: separator, terminator: terminator, to: &stderr);
}
