struct ProducerState: Codable {
	var businessesFileState: CancelableFileReading.State;
	var reviewsFileState: CancelableFileReading.State;
}

extension ProducerState {
	static var empty: ProducerState {
		.init(
			businessesFileState: .new,
			reviewsFileState: .new
		);
	}
}


actor ProducerStateManager {
	private var state: ProducerState;

	init(state: ProducerState) {
		self.state = state
	}

	func update(key: WritableKeyPath<ProducerState, CancelableFileReading.State>, to newValue: CancelableFileReading.State) async throws {
		self.state[keyPath: key] = newValue;
	}

	func writeToDisk() async throws {
		
	}
}

extension ProducerStateManager {
	static var empty: ProducerStateManager {
		.init(state: .empty)
	}
}
