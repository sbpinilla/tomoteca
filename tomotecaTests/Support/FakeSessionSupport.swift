//
//  FakeSessionSupport.swift
//  tomotecaTests
//

import Combine
import Foundation
@testable import tomoteca

/// A clock a test can move by hand, so the countdown can be checked without waiting in real
/// time — and so a 15-minute session can be tested in microseconds.
final class TestClock {

    private(set) var now: Date

    init(now: Date = Date(timeIntervalSince1970: 1_700_000_000)) {
        self.now = now
    }

    func advance(by interval: TimeInterval) {
        now = now.addingTimeInterval(interval)
    }

    /// Passed to the ViewModel in place of `Date.init`.
    var reader: () -> Date { { self.now } }
}

/// Records what would have been scheduled, since a real notification centre cannot be driven
/// from a unit test.
final class FakeNotificationScheduler: SessionNotificationScheduling {

    private(set) var scheduledIntervals: [TimeInterval] = []
    private(set) var cancelCount = 0
    private(set) var authorizationRequests = 0

    func requestAuthorization() async {
        authorizationRequests += 1
    }

    func scheduleSessionEnd(in seconds: TimeInterval, bookTitle: String) {
        scheduledIntervals.append(seconds)
    }

    func cancelScheduledSessionEnd() {
        cancelCount += 1
    }
}

/// In-memory session store for tests.
final class FakeReadingSessionRepository: ReadingSessionRepository {

    var errorToThrow: (any Error)?
    private(set) var added: [ReadingSession] = []

    private let subject = CurrentValueSubject<[ReadingSession], Never>([])

    var sessions: AnyPublisher<[ReadingSession], Never> {
        subject.eraseToAnyPublisher()
    }

    func add(_ session: ReadingSession) throws {
        if let errorToThrow { throw errorToThrow }
        added.append(session)
        subject.send([session] + subject.value)
    }
}
