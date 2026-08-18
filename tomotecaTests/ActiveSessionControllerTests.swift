//
//  ActiveSessionControllerTests.swift
//  tomotecaTests
//

import Foundation
import Testing
@testable import tomoteca

@MainActor
struct ActiveSessionControllerTests {

    private static let start = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeController(
        clock: TestClock,
        store: InMemoryActiveSessionStore,
        notifications: FakeNotificationScheduler = FakeNotificationScheduler()
    ) -> ActiveSessionController {
        ActiveSessionController(
            bookRepository: FakeBookRepository(books: Book.previewCatalog),
            sessionRepository: FakeReadingSessionRepository(),
            notifications: notifications,
            store: store,
            now: clock.reader
        )
    }

    private func runningSession(minutes: Int = 15, startedAt: Date = start) -> StoredSession {
        StoredSession(
            bookID: Book.previewReading.id,
            plannedMinutes: minutes,
            startedAt: startedAt,
            accumulated: 0,
            segmentStartedAt: startedAt
        )
    }

    // MARK: Starting

    @Test("Starting a session stores it, so it outlives the app")
    func startPersistsTheSession() {
        let store = InMemoryActiveSessionStore()
        let controller = makeController(clock: TestClock(now: Self.start), store: store)

        controller.start(book: .previewReading, minutes: 15)

        #expect(store.load()?.bookID == Book.previewReading.id)
        #expect(controller.hasActiveSession)
        #expect(controller.isPresenting)
    }

    @Test("With a session already running, starting another reopens the first")
    func doesNotStartASecondSession() {
        let store = InMemoryActiveSessionStore()
        let controller = makeController(clock: TestClock(now: Self.start), store: store)

        controller.start(book: .previewReading, minutes: 15)
        controller.isPresenting = false

        // Another book, another duration: none of it should replace what is running.
        controller.start(book: .previewOwned, minutes: 30)

        #expect(store.load()?.bookID == Book.previewReading.id)
        #expect(store.load()?.plannedMinutes == 15)
        #expect(controller.isPresenting, "The running session is brought forward instead")
    }

    // MARK: Recovering

    @Test("A session left behind by a previous launch comes back")
    func restoresAStoredSession() {
        let clock = TestClock(now: Self.start.addingTimeInterval(5 * 60))
        let store = InMemoryActiveSessionStore(session: runningSession())

        let controller = makeController(clock: clock, store: store)

        #expect(controller.hasActiveSession)
        #expect(controller.book?.id == Book.previewReading.id)
        #expect(controller.remaining == 10 * 60, "Time passed with the app closed still counts")
        #expect(controller.isExpired == false)
        #expect(controller.isPresenting == false, "It waits behind the banner, it does not barge in")
    }

    @Test("A session whose time ran out while the app was closed comes back as finished")
    func restoresAnExpiredSession() {
        let clock = TestClock(now: Self.start.addingTimeInterval(20 * 60))
        let controller = makeController(
            clock: clock,
            store: InMemoryActiveSessionStore(session: runningSession(minutes: 15))
        )

        #expect(controller.hasActiveSession)
        #expect(controller.isExpired)
        #expect(controller.remaining == 0)
    }

    @Test("A session overdue by more than a day is thrown away, alert included")
    func discardsStaleSessions() {
        let clock = TestClock(now: Self.start.addingTimeInterval(15 * 60 + 25 * 60 * 60))
        let store = InMemoryActiveSessionStore(session: runningSession(minutes: 15))
        let notifications = FakeNotificationScheduler()

        let controller = makeController(clock: clock, store: store, notifications: notifications)

        #expect(controller.hasActiveSession == false)
        #expect(store.load() == nil)
        #expect(notifications.cancelCount == 1)
    }

    @Test("A session just under the limit is still offered")
    func keepsSessionsWithinTheLimit() {
        let clock = TestClock(now: Self.start.addingTimeInterval(15 * 60 + 23 * 60 * 60))
        let controller = makeController(
            clock: clock,
            store: InMemoryActiveSessionStore(session: runningSession(minutes: 15))
        )

        #expect(controller.hasActiveSession)
    }

    @Test("A paused session never goes stale, however long it sits")
    func pausedSessionsDoNotGoStale() {
        var paused = runningSession()
        paused.accumulated = 300
        paused.segmentStartedAt = nil

        let clock = TestClock(now: Self.start.addingTimeInterval(5 * 24 * 60 * 60))
        let controller = makeController(clock: clock, store: InMemoryActiveSessionStore(session: paused))

        #expect(controller.hasActiveSession)
    }

    // MARK: Ending

    @Test("Finishing clears what was stored, so nothing comes back next launch")
    func finishClearsTheStore() {
        let store = InMemoryActiveSessionStore()
        let controller = makeController(clock: TestClock(now: Self.start), store: store)
        controller.start(book: .previewReading, minutes: 15)

        controller.finish()

        #expect(store.load() == nil)
        #expect(controller.hasActiveSession == false)
        #expect(controller.isPresenting == false)
    }

    // MARK: A free session

    @Test("Starting a free session schedules no alert")
    func startingAFreeSessionSchedulesNoAlert() {
        let notifications = FakeNotificationScheduler()
        let controller = makeController(
            clock: TestClock(now: Self.start),
            store: InMemoryActiveSessionStore(),
            notifications: notifications
        )

        controller.start(book: .previewReading, minutes: 0)

        #expect(notifications.scheduledIntervals.isEmpty)
        #expect(controller.isFree)
    }

    @Test("A planned session reports elapsed but is not free")
    func plannedSessionIsNotFree() {
        let controller = makeController(
            clock: TestClock(now: Self.start.addingTimeInterval(5 * 60)),
            store: InMemoryActiveSessionStore(session: runningSession(minutes: 15))
        )

        #expect(controller.isFree == false)
        #expect(controller.elapsed == 5 * 60)
    }

    // MARK: Auto-pausing a free session left in the background

    private func runningFreeSession(startedAt: Date = start) -> StoredSession {
        StoredSession(
            bookID: Book.previewReading.id,
            plannedMinutes: 0,
            startedAt: startedAt,
            accumulated: 0,
            segmentStartedAt: startedAt
        )
    }

    @Test("Backgrounding marks the moment, only for a running free session")
    func backgroundingMarksAFreeRunningSession() {
        let clock = TestClock(now: Self.start.addingTimeInterval(120))
        let store = InMemoryActiveSessionStore(session: runningFreeSession())
        let controller = makeController(clock: clock, store: store)

        controller.appDidEnterBackground()

        #expect(store.load()?.backgroundedAt == clock.now)
    }

    @Test("Backgrounding a planned session marks nothing — it already limits itself")
    func backgroundingAPlannedSessionMarksNothing() {
        let store = InMemoryActiveSessionStore(session: runningSession())
        let controller = makeController(clock: TestClock(now: Self.start), store: store)

        controller.appDidEnterBackground()

        #expect(store.load()?.backgroundedAt == nil)
    }

    @Test("Backgrounding an already-paused free session marks nothing")
    func backgroundingAPausedFreeSessionMarksNothing() {
        var paused = runningFreeSession()
        paused.accumulated = 90
        paused.segmentStartedAt = nil
        let store = InMemoryActiveSessionStore(session: paused)
        let controller = makeController(clock: TestClock(now: Self.start), store: store)

        controller.appDidEnterBackground()

        #expect(store.load()?.backgroundedAt == nil)
    }

    @Test("A short trip to the background does not pause a free session")
    func shortBackgroundDoesNotPause() {
        let clock = TestClock(now: Self.start)
        let store = InMemoryActiveSessionStore(session: runningFreeSession())
        let controller = makeController(clock: clock, store: store)

        controller.appDidEnterBackground()
        clock.advance(by: 5 * 60)  // well under the threshold
        controller.appDidBecomeActive()

        #expect(store.load()?.isPaused == false)
        #expect(store.load()?.backgroundedAt == nil, "The marker is cleared either way")
    }

    @Test("A free session left backgrounded past the threshold is paused with the time it had then")
    func longBackgroundPausesAFreeSession() {
        let clock = TestClock(now: Self.start)
        let store = InMemoryActiveSessionStore(session: runningFreeSession())
        let controller = makeController(clock: clock, store: store)

        clock.advance(by: 90)  // ninety seconds of real reading before backgrounding
        controller.appDidEnterBackground()
        clock.advance(by: 3 * 60 * 60)  // three hours with the phone away
        controller.appDidBecomeActive()

        let stored = store.load()
        #expect(stored?.isPaused == true)
        #expect(stored?.accumulated == 90, "Credited up to leaving, not up to coming back")
        #expect(controller.isFree)
    }

    @Test("The same threshold applies whether the app was only backgrounded or killed outright")
    func restoringAppliesTheSameThreshold() {
        let clock = TestClock(now: Self.start)
        var leftRunning = runningFreeSession()
        leftRunning.accumulated = 90
        leftRunning.segmentStartedAt = Self.start
        leftRunning.backgroundedAt = Self.start  // set right before the process died

        clock.advance(by: 3 * 60 * 60)
        let store = InMemoryActiveSessionStore(session: leftRunning)
        let controller = makeController(clock: clock, store: store)

        #expect(controller.hasActiveSession)
        #expect(store.load()?.isPaused == true)
        #expect(store.load()?.accumulated == 90)
    }

    @Test("A planned session is untouched by backgrounding, however long it lasts")
    func plannedSessionUnaffectedByBackgrounding() {
        let clock = TestClock(now: Self.start)
        let store = InMemoryActiveSessionStore(session: runningSession(minutes: 15))
        let controller = makeController(clock: clock, store: store)

        controller.appDidEnterBackground()
        clock.advance(by: 3 * 60 * 60)
        controller.appDidBecomeActive()

        // Untouched by the free-session machinery; it is simply expired on its own terms.
        #expect(controller.isExpired)
        #expect(store.load()?.backgroundedAt == nil)
    }
}
