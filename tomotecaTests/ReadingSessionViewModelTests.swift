//
//  ReadingSessionViewModelTests.swift
//  tomotecaTests
//

import Foundation
import Testing
@testable import tomoteca

@MainActor
struct ReadingSessionViewModelTests {

    private struct Harness {
        let viewModel: ReadingSessionViewModel
        let clock: TestClock
        let notifications: FakeNotificationScheduler
        let sessions: FakeReadingSessionRepository
        let books: FakeBookRepository
        let store: InMemoryActiveSessionStore
    }

    private func makeHarness(
        book: Book = .previewReading,
        minutes: Int = 15,
        stored: StoredSession? = nil,
        clock: TestClock = TestClock()
    ) -> Harness {
        let notifications = FakeNotificationScheduler()
        let sessions = FakeReadingSessionRepository()
        let books = FakeBookRepository(books: [book])

        let session = stored ?? StoredSession(
            bookID: book.id,
            plannedMinutes: minutes,
            startedAt: clock.now,
            accumulated: 0,
            segmentStartedAt: clock.now
        )
        let store = InMemoryActiveSessionStore(session: session)

        return Harness(
            viewModel: ReadingSessionViewModel(
                book: book,
                stored: session,
                repository: books,
                sessionRepository: sessions,
                notifications: notifications,
                store: store,
                now: clock.reader
            ),
            clock: clock,
            notifications: notifications,
            sessions: sessions,
            books: books,
            store: store
        )
    }

    // MARK: Countdown

    @Test("A session starts running with its full time ahead")
    func startsWithFullTime() {
        let h = makeHarness(minutes: 15)

        #expect(h.viewModel.phase == .running)
        #expect(h.viewModel.remaining == 15 * 60)
        #expect(h.viewModel.progress == 0)
    }

    @Test("The countdown follows the clock")
    func countsDown() {
        let h = makeHarness(minutes: 15)

        h.clock.advance(by: 60)
        h.viewModel.refresh()

        #expect(h.viewModel.remaining == 14 * 60)
        #expect(h.viewModel.elapsed == 60)
    }

    @Test("Time spent in the background still counts")
    func survivesTheBackground() {
        let h = makeHarness(minutes: 15)

        // No ticks at all while the app was away: eight minutes pass in one jump, exactly as
        // they would after the phone was locked.
        h.clock.advance(by: 8 * 60)
        h.viewModel.refresh()

        #expect(h.viewModel.elapsed == 8 * 60)
        #expect(h.viewModel.remaining == 7 * 60)
    }

    @Test("When the time runs out the session asks for the page")
    func asksForThePageWhenTimeIsUp() {
        let h = makeHarness(minutes: 10)

        h.clock.advance(by: 10 * 60)
        h.viewModel.refresh()

        #expect(h.viewModel.phase == .askingPage)
        #expect(h.viewModel.remaining == 0)
    }

    @Test("The countdown never goes below zero, however late the app comes back")
    func doesNotGoNegative() {
        let h = makeHarness(minutes: 10)

        h.clock.advance(by: 60 * 60)
        h.viewModel.refresh()

        #expect(h.viewModel.remaining == 0)
        #expect(h.viewModel.progress == 1)
    }

    // MARK: Pause

    @Test("Pausing stops the clock from running away")
    func pauseFreezesTheCountdown() {
        let h = makeHarness(minutes: 15)

        h.clock.advance(by: 120)
        h.viewModel.refresh()
        h.viewModel.pause()

        h.clock.advance(by: 600)  // ten minutes on the shelf
        h.viewModel.refresh()

        #expect(h.viewModel.phase == .paused)
        #expect(h.viewModel.elapsed == 120, "Paused time must not count as read")
        #expect(h.viewModel.remaining == 13 * 60)
    }

    @Test("Resuming picks up where it left off")
    func resumeContinues() {
        let h = makeHarness(minutes: 15)

        h.clock.advance(by: 120)
        h.viewModel.refresh()
        h.viewModel.pause()
        h.clock.advance(by: 600)
        h.viewModel.resume()

        h.clock.advance(by: 60)
        h.viewModel.refresh()

        #expect(h.viewModel.phase == .running)
        #expect(h.viewModel.elapsed == 180)
    }

    // MARK: Notifications

    @Test("Pausing cancels the alert, and resuming schedules it for the time that is left")
    func reschedulesAroundPause() {
        let h = makeHarness(minutes: 15)

        h.clock.advance(by: 300)
        h.viewModel.refresh()
        h.viewModel.pause()

        #expect(h.notifications.cancelCount == 1)

        h.viewModel.resume()

        #expect(h.notifications.scheduledIntervals == [10 * 60])
    }

    @Test("Finishing early cancels the pending alert")
    func cancelsTheAlertWhenFinishingEarly() {
        let h = makeHarness(minutes: 15)

        h.viewModel.finishEarly()

        #expect(h.notifications.cancelCount == 1)
    }

    // MARK: Finishing early

    @Test("Finishing early keeps the time already read")
    func finishingEarlyKeepsTheTimeRead() {
        let h = makeHarness(minutes: 15)

        h.clock.advance(by: 6 * 60)
        h.viewModel.refresh()
        h.viewModel.finishEarly()

        #expect(h.viewModel.phase == .askingPage)
        #expect(h.viewModel.elapsed == 6 * 60)
    }

    @Test("The session records what was read, not what was planned")
    func recordsRealTimeNotPlanned() throws {
        let h = makeHarness(minutes: 15)

        h.clock.advance(by: 6 * 60)
        h.viewModel.refresh()
        h.viewModel.finishEarly()
        h.viewModel.finalPageText = "250"

        #expect(h.viewModel.save())

        let session = try #require(h.sessions.added.first)
        #expect(session.actualSeconds == 6 * 60)
        #expect(session.plannedMinutes == 15)
    }

    // MARK: The final page

    @Test("The page starts at wherever the reader already was")
    func pageStartsAtTheCurrentBookmark() {
        let h = makeHarness()
        #expect(h.viewModel.finalPageText == String(Book.previewReading.currentPage))
    }

    @Test("Pages beyond the end of the book are rejected", arguments: ["341", "9999", "-1", "abc", ""])
    func rejectsImpossiblePages(_ input: String) {
        let h = makeHarness()  // the sample book has 340 pages

        h.viewModel.finalPageText = input

        #expect(h.viewModel.finalPage == nil)
        #expect(h.viewModel.canSave == false)
    }

    @Test("The last page of the book is a valid answer")
    func acceptsTheLastPage() {
        let h = makeHarness()

        h.viewModel.finalPageText = "340"

        #expect(h.viewModel.finalPage == 340)
        #expect(h.viewModel.canSave)
    }

    @Test("A page out of range is explained rather than silently ignored")
    func explainsAPageOutOfRange() {
        let h = makeHarness()

        h.viewModel.finalPageText = "500"

        #expect(h.viewModel.showsPageOutOfRange)
    }

    @Test("Saving moves the book's bookmark to the page just entered")
    func savingMovesTheBookmark() throws {
        let h = makeHarness()

        h.viewModel.finishEarly()
        h.viewModel.finalPageText = "260"

        #expect(h.viewModel.save())

        let stored = try #require(h.books.updated.first)
        #expect(stored.currentPage == 260)
        #expect(stored.id == Book.previewReading.id)
    }

    @Test("The session records the page it started on, which is where the bookmark was")
    func recordsTheStartingPage() throws {
        let h = makeHarness()

        h.viewModel.finishEarly()
        h.viewModel.finalPageText = "260"

        #expect(h.viewModel.save())

        let session = try #require(h.sessions.added.first)
        #expect(session.startPage == Book.previewReading.currentPage)
        #expect(session.finalPage == 260)
        #expect(session.pagesRead == 260 - Book.previewReading.currentPage)
    }

    @Test("Saving does not touch the book's status: finishing a book stays a deliberate act")
    func savingDoesNotAdvanceTheStatus() throws {
        let h = makeHarness()

        h.viewModel.finishEarly()
        h.viewModel.finalPageText = "340"  // the very last page

        #expect(h.viewModel.save())

        let stored = try #require(h.books.updated.first)
        #expect(stored.status == .reading)
    }

    @Test("A failed write leaves the session open instead of losing the time read")
    func keepsTheSessionOpenIfStoringFails() {
        let h = makeHarness()
        h.sessions.errorToThrow = StubError()

        h.viewModel.finishEarly()
        h.viewModel.finalPageText = "250"

        #expect(h.viewModel.save() == false)
        #expect(h.viewModel.phase == .askingPage)
    }

    // MARK: Surviving the app being killed

    @Test("Pausing and resuming are written down, not just held in memory")
    func persistsPauseAndResume() throws {
        let h = makeHarness(minutes: 15)

        h.clock.advance(by: 120)
        h.viewModel.refresh()
        h.viewModel.pause()

        let paused = try #require(h.store.load())
        #expect(paused.isPaused)
        #expect(paused.accumulated == 120)

        h.clock.advance(by: 600)
        h.viewModel.resume()

        #expect(try #require(h.store.load()).isPaused == false)
    }

    @Test("A session picked up after a relaunch keeps the time it had already run")
    func resumesFromStoredState() {
        let clock = TestClock()
        let started = clock.now
        clock.advance(by: 6 * 60)  // six minutes passed with the app dead

        let h = makeHarness(
            stored: StoredSession(
                bookID: Book.previewReading.id,
                plannedMinutes: 15,
                startedAt: started,
                accumulated: 0,
                segmentStartedAt: started
            ),
            clock: clock
        )

        #expect(h.viewModel.phase == .running)
        #expect(h.viewModel.elapsed == 6 * 60)
        #expect(h.viewModel.remaining == 9 * 60)
    }

    @Test("A session whose time ran out while the app was dead opens asking for the page")
    func expiredSessionAsksForThePage() {
        let clock = TestClock()
        let started = clock.now
        clock.advance(by: 20 * 60)  // well past a 15-minute session

        let h = makeHarness(
            stored: StoredSession(
                bookID: Book.previewReading.id,
                plannedMinutes: 15,
                startedAt: started,
                accumulated: 0,
                segmentStartedAt: started
            ),
            clock: clock
        )

        #expect(h.viewModel.phase == .askingPage)
        #expect(h.notifications.cancelCount == 1, "Its alert has already fired or is moot")
    }

    @Test("A session that ran its course records the planned time, not the hours since")
    func expiredSessionRecordsThePlannedTime() throws {
        let clock = TestClock()
        let started = clock.now
        clock.advance(by: 3 * 60 * 60)  // came back three hours later

        let h = makeHarness(
            stored: StoredSession(
                bookID: Book.previewReading.id,
                plannedMinutes: 15,
                startedAt: started,
                accumulated: 0,
                segmentStartedAt: started
            ),
            clock: clock
        )
        h.viewModel.finalPageText = "260"

        #expect(h.viewModel.save())
        #expect(try #require(h.sessions.added.first).actualSeconds == 15 * 60)
    }

    @Test("Saving clears the stored session, so nothing is offered again next launch")
    func savingClearsTheStoredSession() {
        let h = makeHarness()

        h.viewModel.finishEarly()
        h.viewModel.finalPageText = "250"

        #expect(h.viewModel.save())
        #expect(h.store.load() == nil)
    }

    @Test("A session waiting for its page is kept, so killing the app now does not lose it")
    func keepsTheSessionWhileAskingForThePage() {
        let h = makeHarness()

        h.clock.advance(by: 4 * 60)
        h.viewModel.refresh()
        h.viewModel.finishEarly()

        #expect(h.store.load() != nil)
    }

    // MARK: A free session

    @Test("A free session starts at zero, counting up")
    func freeSessionStartsAtZero() {
        let h = makeHarness(minutes: 0)

        #expect(h.viewModel.isFree)
        #expect(h.viewModel.elapsedTime == 0)
        #expect(h.viewModel.remaining == 0, "Nothing to count down to")
        #expect(h.viewModel.progress == 0, "No plan for the ring to be a fraction of")
    }

    @Test("A free session's clock counts up, and never asks for the page on its own")
    func freeSessionCountsUp() {
        let h = makeHarness(minutes: 0)

        h.clock.advance(by: 40 * 60)  // well past any of the fixed durations
        h.viewModel.refresh()

        #expect(h.viewModel.elapsedTime == 40 * 60)
        #expect(h.viewModel.phase == .running, "Only the reader ends a free session")
    }

    @Test("Pausing a free session freezes elapsed time; resuming continues it")
    func freeSessionPauseAndResume() {
        let h = makeHarness(minutes: 0)

        h.clock.advance(by: 120)
        h.viewModel.refresh()
        h.viewModel.pause()

        h.clock.advance(by: 600)
        h.viewModel.refresh()
        #expect(h.viewModel.elapsedTime == 120, "Paused time must not count as read")

        h.viewModel.resume()
        h.clock.advance(by: 30)
        h.viewModel.refresh()

        #expect(h.viewModel.elapsedTime == 150)
    }

    @Test("Starting or resuming a free session schedules no alert")
    func freeSessionSchedulesNoAlert() {
        let h = makeHarness(minutes: 0)

        h.clock.advance(by: 60)
        h.viewModel.pause()
        h.viewModel.resume()

        #expect(h.notifications.scheduledIntervals.isEmpty)
    }

    @Test("Finishing a free session credits every second read, uncapped")
    func freeSessionClosesOutWithoutCapping() throws {
        let h = makeHarness(minutes: 0)

        h.clock.advance(by: 47 * 60)
        h.viewModel.refresh()
        h.viewModel.finishEarly()
        h.viewModel.finalPageText = "260"

        #expect(h.viewModel.save())

        let session = try #require(h.sessions.added.first)
        #expect(session.actualSeconds == 47 * 60, "A free session has no plan to be capped at")
        #expect(session.plannedMinutes == 0)
    }

    @Test("A free session recovered after a relaunch keeps counting up, never expired")
    func freeSessionResumesFromStoredState() {
        let clock = TestClock()
        let started = clock.now
        clock.advance(by: 3 * 60 * 60)  // three hours with the app dead

        let h = makeHarness(
            stored: StoredSession(
                bookID: Book.previewReading.id,
                plannedMinutes: 0,
                startedAt: started,
                accumulated: 0,
                segmentStartedAt: started
            ),
            clock: clock
        )

        #expect(h.viewModel.phase == .running, "A free session never opens straight to asking for the page")
        #expect(h.viewModel.elapsedTime == 3 * 60 * 60)
    }

    @Test("reload(from:) brings the ViewModel back in line with a session paused from outside it")
    func reloadPicksUpAnExternalPause() throws {
        let h = makeHarness(minutes: 0)

        h.clock.advance(by: 90)
        var pausedElsewhere = try #require(h.store.load())
        pausedElsewhere.accumulated = 90
        pausedElsewhere.segmentStartedAt = nil

        h.viewModel.reload(from: pausedElsewhere)

        #expect(h.viewModel.phase == .paused)
        #expect(h.viewModel.elapsedTime == 90)
    }
}
