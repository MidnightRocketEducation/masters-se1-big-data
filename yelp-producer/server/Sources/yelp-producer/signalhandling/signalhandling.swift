import Foundation;

typealias Signal = Int32;
extension Signal {
	static let HUP: Signal = SIGHUP;
	static let INT: Signal = SIGINT;
	static let QUIT: Signal = SIGQUIT;
	static let TERM: Signal = SIGTERM;
	static let PIPE: Signal = SIGPIPE;
}

struct SignalHandler {
	private static let handlers: AsyncDictionary<Signal, CheckedContinuation<Int32, Never>> = .init();

	private static func save(_ continuation: CheckedContinuation<Int32, Never>, for sig: Signal) {
		Task {
			await Self.handlers.set(sig, value: continuation);
		}
	}

	private static func trigger(_ sig: Signal) {
		// Detached with high priority to process signal as fast a possible
		Task.detached(priority: .high) {
			await Self.handlers.removeValue(forKey: sig)?.resume(returning: sig);
		}
	}

	static func register(_ signals: Signal..., handle: @escaping @Sendable (Signal) async -> ExitCode) {
		Self.register(signals, handle: handle);
	}

	static func register(_ signals: [Signal], handle: @escaping @Sendable (Signal) async -> ExitCode) {
		// Detached with high priority to process signal as fast a possible
		Task.detached(priority: .high) {
			await withTaskGroup(of: Signal.self) { group in
				for sig in signals {
					group.addTask {
						await withCheckedContinuation { continuation in
							Self.save(continuation, for: sig);
							signal(sig) {
								Self.trigger($0);
							}
						}
					}
				}

				// Wait for one signal to be recieved (the first to finish).
				guard let s = await group.next() else {
					return;
				}

				Foundation.exit(await handle(s));
			}
		}
	}
}


typealias ExitCode = Int32;
extension ExitCode {
	static let ok: ExitCode = 0;
	static let error: ExitCode = 1;
	static let intrrupted: ExitCode = 130;
}
