actor AsyncSignal<Value: Sendable> {
	private var queue: [CheckedContinuation<Value, Never>] = [];

	func nextSignal() async -> Value {
		return await withCheckedContinuation { continuation in
			queue.append(continuation);
		}
	}

	func sendToFirst(_ value: Value) {
		guard !self.queue.isEmpty else { return }
		self.queue.removeFirst().resume(returning: value);
	}

	func sendToAll(_ value: Value) {
		while !self.queue.isEmpty {
			self.queue.removeFirst().resume(returning: value);
		}
	}
}

extension AsyncSignal where Value == Void {
	func sendToFirst() {
		self.sendToFirst(());
	}

	func sendToAll() {
		self.sendToAll(());
	}
}
