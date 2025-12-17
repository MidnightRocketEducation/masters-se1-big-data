import Foundation;

actor AsyncLimitedBatchProcessor {
	let batchSize: Int;
	let signalAvailableProcessors: AsyncSignal<Void> = .init();
	var availableProcessors: [AsyncSignal<Command>] = [];
	var taskGroup: Task<Void, Never>? = nil;
	var stopped: Bool = false;

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
				for _ in 0..<self.batchSize {
					taskGroup.addTask {
						await self.processJobs();
					}
				}
			}
		}
	}

	func add(_ job: @Sendable @escaping () async -> ()) async {
		assert(!self.stopped, "Called add after finish");
		while self.availableProcessors.isEmpty {
			await signalAvailableProcessors.nextSignal();
		}
		await self.availableProcessors.removeFirst().sendToFirst(.job(job));
	}

	func finish() async {
		while !self.availableProcessors.isEmpty {
			await self.availableProcessors.removeFirst().sendToFirst(.quit);
		}
		await taskGroup?.value;
	}

	private func processJobs() async {
		while case let .job(j) = await self.getNextCommand() {
			await j();
		}
	}

	private func getNextCommand() async -> Command {
		guard !self.stopped else {
			return .quit;
		}

		let sig = AsyncSignal<Command>();
		availableProcessors.append(sig);
		async let command = await sig.nextSignal();
		await self.signalAvailableProcessors.sendToFirst();
		return await command;
	}
}


extension AsyncLimitedBatchProcessor {
	enum Command: Sendable {
		case quit;
		case job(@Sendable () async -> Void);
	}
}
