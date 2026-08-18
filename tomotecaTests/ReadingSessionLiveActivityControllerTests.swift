//
//  ReadingSessionLiveActivityControllerTests.swift
//  tomotecaTests
//

import Foundation
import Testing
@testable import tomoteca

/// Covers `contentState(for:)` only — the one piece of the controller that is pure. Starting,
/// updating and ending a real `Activity` needs a capable device and entitlements a unit test has
/// neither of; `ActiveSessionControllerTests` covers that this type is asked the right things,
/// through `FakeLiveActivityUpdating`.
///
/// The test target's own floor is 16.0, same as the app's — so each test that touches
/// `ReadingSessionLiveActivityController` (iOS 16.2) carries its own `@available`, same as any
/// other call site would.
@MainActor
struct ReadingSessionLiveActivityControllerTests {

    private static let start = Date(timeIntervalSince1970: 1_700_000_000)

    private func session(minutes: Int = 15, accumulated: TimeInterval = 0, paused: Bool = false) -> StoredSession {
        StoredSession(
            bookID: UUID(),
            plannedMinutes: minutes,
            startedAt: Self.start,
            accumulated: accumulated,
            segmentStartedAt: paused ? nil : Self.start
        )
    }

    @Test("Running with a plan hands over an end date, for the system to animate the countdown")
    @available(iOS 16.2, *)
    func runningWithAPlan() {
        let controller = ReadingSessionLiveActivityController(now: { Self.start.addingTimeInterval(5 * 60) })
        let stored = session(minutes: 15)

        let state = controller.contentState(for: stored)

        #expect(state.endDate == Self.start.addingTimeInterval(15 * 60))
        #expect(state.frozenDisplay == "10:00")
        #expect(state.isPaused == false)
        #expect(state.isFree == false)
    }

    @Test("Paused with a plan freezes on the remaining time, with no end date to animate towards")
    @available(iOS 16.2, *)
    func pausedWithAPlan() {
        let controller = ReadingSessionLiveActivityController(now: { Self.start.addingTimeInterval(20 * 60) })
        let stored = session(minutes: 15, accumulated: 5 * 60, paused: true)

        let state = controller.contentState(for: stored)

        #expect(state.endDate == nil)
        #expect(state.frozenDisplay == "10:00")
        #expect(state.isPaused == true)
        #expect(state.isFree == false)
    }

    @Test("A running free session freezes on the time read so far, counting up rather than down")
    @available(iOS 16.2, *)
    func runningFree() {
        let controller = ReadingSessionLiveActivityController(now: { Self.start.addingTimeInterval(90) })
        let stored = session(minutes: 0)

        let state = controller.contentState(for: stored)

        #expect(state.endDate == nil)
        #expect(state.frozenDisplay == "01:30")
        #expect(state.isPaused == false)
        #expect(state.isFree == true)
    }

    @Test("A paused free session freezes on what had been banked, same as any other pause")
    @available(iOS 16.2, *)
    func pausedFree() {
        let controller = ReadingSessionLiveActivityController(now: { Self.start.addingTimeInterval(999) })
        let stored = session(minutes: 0, accumulated: 42, paused: true)

        let state = controller.contentState(for: stored)

        #expect(state.endDate == nil)
        #expect(state.frozenDisplay == "00:42")
        #expect(state.isPaused == true)
        #expect(state.isFree == true)
    }
}
