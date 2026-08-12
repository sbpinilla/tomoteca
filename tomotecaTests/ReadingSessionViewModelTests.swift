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
    }

    private func makeHarness(
        book: Book = .previewReading,
        minutes: Int = 15
    ) -> Harness {
        let clock = TestClock()
        let notifications = FakeNotificationScheduler()
        let sessions = FakeReadingSessionRepository()
        let books = FakeBookRepository(books: [book])

        return Harness(
            viewModel: ReadingSessionViewModel(
                book: book,
                plannedMinutes: minutes,
                repository: books,
                sessionRepository: sessions,
                notifications: notifications,
                now: clock.reader
            ),
            clock: clock,
            notifications: notifications,
            sessions: sessions,
            books: books
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

    @Test("The end-of-session alert is scheduled when the session starts")
    func schedulesTheAlertOnStart() {
        let h = makeHarness(minutes: 15)
        #expect(h.notifications.scheduledIntervals == [15 * 60])
    }

    @Test("Pausing cancels the alert, and resuming schedules it for the time that is left")
    func reschedulesAroundPause() {
        let h = makeHarness(minutes: 15)

        h.clock.advance(by: 300)
        h.viewModel.refresh()
        h.viewModel.pause()

        #expect(h.notifications.cancelCount == 1)

        h.viewModel.resume()

        #expect(h.notifications.scheduledIntervals == [15 * 60, 10 * 60])
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
}
