import Foundation;

actor AsyncLimitedBatchProcessor {
	let batchSize: Int;
	private var jobWaitingQueue: [CheckedContinuation<QueueStatus, Never>] = [];
	private var availableProcessors: [CheckedContinuation<Command, Never>] = [];
	private var taskGroup: Task<Void, Never>? = nil;
	private var hasBeenCancelled: Bool = false;

	init(batchSize: Int) async {
		self.batchSize = batchSize;
		self.startProcessor();
	}

	private func startProcessor() {
		guard taskGroup == nil else {
			return;
		}
		self.taskGroup = .init {
			await withTaskGroup { taskGroup in
				for id in 0..<self.batchSize {
					taskGroup.addTask {
						await self.processJobs(id: id);
					}
				}
			}
		}
	}

	func add(_ job: @Sendable @escaping () async -> ()) async throws {
		assert(!self.hasBeenCancelled, "Called add after finish");
		while self.availableProcessors.isEmpty {
			guard case .workerAvailable = await withCheckedContinuation({jobWaitingQueue.append($0)}) else {
				throw Error.cancelled;
			}
		}
		self.availableProcessors.removeFirst().resume(returning: .job(job));
	}

	func cancel() async {
		self.hasBeenCancelled = true;
		while !self.availableProcessors.isEmpty {
			self.availableProcessors.removeFirst().resume(returning: .quit);
		}
		while !self.jobWaitingQueue.isEmpty {
			self.jobWaitingQueue.removeFirst().resume(returning: .cancelled);
		}
		self.taskGroup?.cancel();
		await taskGroup?.value;
	}

	private func processJobs(id: Int) async {
		while case let .job(j) = await self.getNextCommand(id: id) {
			assert(!self.hasBeenCancelled, "Job tried to execute but processor was cancelled");
			await j();
		}
	}

	private func getNextCommand(id: Int) async -> Command {
		guard !self.hasBeenCancelled else {
			return .quit;
		}

		return await withCheckedContinuation { continuation in
			self.availableProcessors.append(continuation);
			if !self.jobWaitingQueue.isEmpty {
				self.jobWaitingQueue.removeFirst().resume(returning: .workerAvailable);
			}
		}
	}
}


extension AsyncLimitedBatchProcessor {
	enum Command: Sendable {
		case quit;
		case job(@Sendable () async -> Void);
	}

	enum QueueStatus: Sendable {
		case workerAvailable;
		case cancelled;
	}

	enum Error: Swift.Error {
		case cancelled;
	}
}
