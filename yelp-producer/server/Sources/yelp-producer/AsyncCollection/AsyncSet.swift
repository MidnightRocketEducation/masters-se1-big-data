actor AsyncSet<Element: Hashable & Sendable> {
	typealias Container = Set<Element>;

	private var container: Container;

	init() {
		self.container = .init();
	}

	subscript(index: Container.Index) -> Element? {
		return self.container[index];
	}

	func get(_ index: Container.Index) -> Element? {
		return self[index];
	}

	func remove(_ member: Element) -> Element? {
		return self.container.remove(member);
	}

	func contains(_ member: Element) -> Bool {
		return self.container.contains(member);
	}

	@discardableResult
	func insert(_ member: Element) -> (inserted: Bool, memberAfterInsert: Element) {
		return self.container.insert(member);
	}
}
