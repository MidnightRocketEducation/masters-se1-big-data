import Foundation;

actor AsyncLimitedBatchProcessor {
	let batchSize: Int;
	private let signalAvailableProcessors: AsyncSignal<QueueStatus> = .init();
	private var availableProcessors: [AsyncSignal<Command>] = [];
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
				for i in 0..<self.batchSize {
					taskGroup.addTask {
						await self.processJobs(id: i);
					}
				}
			}
		}
	}

	func add(_ job: @Sendable @escaping () async -> ()) async throws {
		assert(!self.hasBeenCancelled, "Called add after finish");
		while self.availableProcessors.isEmpty {
			guard case .workerAvailable = await signalAvailableProcessors.nextSignal() else {
				throw Error.cancelled;
			}
		}
		await self.availableProcessors.removeFirst().sendToFirst(.job(job));
	}

	func cancel() async {
		assert(!self.hasBeenCancelled, "Cancel has been called multiple times");
		self.hasBeenCancelled = true;
		while !self.availableProcessors.isEmpty {
			await self.availableProcessors.removeFirst().sendToFirst(.quit);
		}
		await self.signalAvailableProcessors.sendToAll(.cancelled);
		await taskGroup?.value;
	}

	private func processJobs(id: Int) async {
		while case let .job(j) = await self.getNextCommand() {
			assert(!self.hasBeenCancelled, "Job tried to execute but processor was cancelled");
			await j();
		}
	}

	private func getNextCommand() async -> Command {
		guard !self.hasBeenCancelled else {
			return .quit;
		}

		let sig = AsyncSignal<Command>();
		availableProcessors.append(sig);
		async let command = await sig.nextSignal();
		await self.signalAvailableProcessors.sendToFirst(.workerAvailable);
		return await command;
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
