import Foundation;

actor ClockContinuity {
	private var previouslyReturnedTime: Date;
	private var _currentTime: Date;
	private var intactContinuity: Bool = true;

	var currentTime: (date: Date, intactContinuity: Bool) {
		self.intactContinuity = self.previouslyReturnedTime <= self._currentTime;
		self.previouslyReturnedTime = self._currentTime;
		return (self._currentTime, self.intactContinuity);
	}

	private let notifier: AsyncSignal<Date> = .init();

	init(currentTime: Date) {
		self._currentTime = currentTime;
		self.previouslyReturnedTime = currentTime;
	}


	func set(_ newTime: Date) async {
		self._currentTime = newTime;
		await self.notifier.sendToAll(newTime);
	}

	func waitUntil(condition: (Date) -> Bool) async -> Date {
		while !condition(self.currentTime.date) {
			_ = await self.waitUntilUpdated();
		}
		return self.currentTime.date;
	}

	func waitUntilUpdated() async -> Date {
		return await self.notifier.nextSignal();
	}

	func clearContinuity() {
		self.intactContinuity = true;
	}

	func getWithSafeContinuity() throws -> Date {
		let (currentTime, intactContinuity) = self.currentTime;
		guard intactContinuity else {
			throw Error.invalidContinuity;
		}
		return currentTime;
	}

	func waitUntilUpdatedWithSafeContinuity() async throws -> Date {
		_ = await self.waitUntilUpdated();
		return try self.getWithSafeContinuity();
	}
}

extension ClockContinuity {
	enum Error: Swift.Error {
		case invalidContinuity;
	}
}
