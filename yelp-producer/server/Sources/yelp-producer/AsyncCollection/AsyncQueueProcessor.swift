import Foundation;


actor AsyncQueueProcessor<R: Sendable> {
	typealias Element = @Sendable () async -> R;
	private let continuation: AsyncStream<Element>.Continuation;

	let task: Task<[R], Never>;

	init() {
		let (stream, continuation) = AsyncStream<Element>.makeStream();
		self.continuation = continuation;
		self.task = .init {
			var results: [R] = [];
			for await f in stream {
				results.append(await f());
			}
			return results;
		}
	}

	func add(function: @escaping Element) {
		self.continuation.yield(function);
	}

	func finish() async -> [R] {
		self.continuation.finish();
		return await self.task.value;
	}
}
