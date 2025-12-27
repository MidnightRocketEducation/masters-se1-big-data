import Foundation;

actor ClockContinuity {
	private let notifier: AsyncSignal<Result<Date, Error>> = .init();
	private var previouslyReturnedTime: Date;
	private var _currentTime: Date;
	private var intactContinuity: Bool = true;

	var currentTime: (date: Date, intactContinuity: Bool) {
		self.intactContinuity = self.previouslyReturnedTime <= self._currentTime;
		self.previouslyReturnedTime = self._currentTime;
		return (self._currentTime, self.intactContinuity);
	}

	init(currentTime: Date) {
		self._currentTime = currentTime;
		self.previouslyReturnedTime = currentTime;
	}


	func set(_ newTime: Date) async {
		self._currentTime = newTime;
		await self.notifier.sendToAll(.success(newTime));
	}

	func waitUntil(condition: (Date) -> Bool) async throws -> Date {
		while !condition(self._currentTime) {
			_ = try await self.waitUntilUpdated();
		}
		return self.currentTime.date;
	}

	func waitUntilUpdated() async throws -> Date {
		return try await self.notifier.nextSignal().get();
	}

	func clearContinuity() {
		self.intactContinuity = true;
		self.previouslyReturnedTime = .distantPast;
	}

	func getWithSafeContinuity() throws -> Date {
		let (currentTime, intactContinuity) = self.currentTime;
		guard intactContinuity else {
			throw Error.brokenContinuity;
		}
		return currentTime;
	}

	func waitUntilUpdatedWithSafeContinuity() async throws -> Date {
		_ = try await self.waitUntilUpdated();
		return try self.getWithSafeContinuity();
	}

	func waitUntilWithSafeContinuity(condition: (Date) -> Bool) async throws -> Date {
		while !condition(try self.getWithSafeContinuity()) {
			_ = try await self.waitUntilUpdated();
		}
		return try self.getWithSafeContinuity();
	}

	func cancelAll() async {
		await self.notifier.sendToAll(.failure(Error.waitCancelled));
	}
}

extension ClockContinuity {
	enum Error: Swift.Error {
		case brokenContinuity;
		case waitCancelled;
	}
}
