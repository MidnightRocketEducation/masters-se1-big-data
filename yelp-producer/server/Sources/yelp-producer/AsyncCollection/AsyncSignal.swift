actor AsyncSignal<Value: Sendable> {
	private var queue: [CheckedContinuation<Value, Never>] = [];
	private var signalQueue: [Value] = [];

	func nextSignal() async -> Value {
		guard !self.signalQueue.isEmpty else {
			return await withCheckedContinuation { continuation in
				self.queue.append(continuation);
			}
		}
		return self.signalQueue.removeFirst();
	}

	@discardableResult
	func sendToFirst(_ value: Value) -> Bool {
		guard !self.queue.isEmpty else {
			self.signalQueue.append(value);
			return false;
		}
		self.queue.removeFirst().resume(returning: value);
		return true;
	}

	func sendToAll(_ value: Value) {
		repeat {
			self.sendToFirst(value)
		} while !self.queue.isEmpty;
	}
}

extension AsyncSignal where Value == Void {
	func sendToFirst() -> Bool {
		return self.sendToFirst(());
	}

	func sendToAll() {
		self.sendToAll(());
	}
}
