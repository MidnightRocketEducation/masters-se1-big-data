import Foundation;

enum ENV {
	static let prefix = "YP_"; // YP for Yelp Producer


	var value: String? {
		ProcessInfo.processInfo.environment[self.name];
	}

	var name: String {
		Self.prefix + String(describing: self);
	}
}
