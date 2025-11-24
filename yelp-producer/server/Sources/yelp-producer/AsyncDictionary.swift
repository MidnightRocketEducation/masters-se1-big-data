actor AsyncDictionary<Key: Hashable, Value> {
	private var dictionary: [Key: Value];

	init() {
		self.dictionary = [:];
	}

	subscript(key: Key) -> Value? {
		get {
			return self.dictionary[key];
		} set {
			self.dictionary[key] = newValue;
		}
	}

	func getOrSet(_ key: Key, value: () throws -> Value) rethrows -> Value {
		try self.getOrSet(key, value());
	}

	func getOrSet(_ key: Key, _ value: @autoclosure () throws -> Value) rethrows -> Value {
		/*
		 The problem with `await` inside actor methods is that other threads can execute and change state.
		 This may lead to a race condition, which creates multiple instances of Cache using the same path.
		 See: https://forums.swift.org/t/awaiting-a-result-in-actor/77323/6
		 */
		if let existing = self[key] {
			return existing;
		}
		let v =  try value();
		self[key] = v;
		return v;
	}

	func set(_ key: Key, value: Value) {
		self[key] = value;
	}

	func get(_ key: Key) -> Value? {
		self[key]
	}

	func removeValue(forKey key: Key) -> Value? {
		self.dictionary.removeValue(forKey: key);
	}
}
