struct Location: Codable {
	let coordinates: Coordinates;
}

extension Location {
	struct Coordinates: Codable {
		let latitude: Double;
		let longitude: Double;

		init(_ latitude: Double, _ longitude: Double) {
			self.latitude = latitude;
			self.longitude = longitude;
		}
	}
}
