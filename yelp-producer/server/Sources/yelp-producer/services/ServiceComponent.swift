protocol ServiceComponent<R> {
	associatedtype R;
	func run() async throws -> R;
	func cancel() async -> Void;
}
