//
//  TrackingViewModelTests.swift
//  tomotecaTests
//

import Foundation
import Testing
@testable import tomoteca

@MainActor
struct TrackingViewModelTests {

    /// A fixed "today" so the range never depends on the day the suite runs, and UTC so a
    /// machine in another zone does not put a session on the wrong side of midnight.
    private static let today = Date(timeIntervalSince1970: 1_700_000_000)

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    /// The catalog the history resolves names against. Defaults to the book every helper session
    /// below belongs to, so a test only passes it when it cares about the join.
    private func makeViewModel(
        sessions: [ReadingSession],
        books: [Book] = [.previewReading]
    ) -> TrackingViewModel {
        TrackingViewModel(
            repository: FakeReadingSessionRepository(seeded: sessions),
            bookRepository: FakeBookRepository(books: books),
            calendar: Self.calendar,
            now: { Self.today }
        )
    }

    /// A session of `minutes` minutes, `daysAgo` days before the fixed today.
    private func session(
        daysAgo: Int,
        minutes: Int,
        book: Book = .previewReading,
        startPage: Int = 100,
        finalPage: Int = 100
    ) -> ReadingSession {
        let day = Self.calendar.date(
            byAdding: .day,
            value: -daysAgo,
            to: Self.calendar.startOfDay(for: Self.today)
        )!
        let started = day.addingTimeInterval(20 * 3600)

        return ReadingSession(
            bookID: book.id,
            startedAt: started,
            endedAt: started.addingTimeInterval(TimeInterval(minutes * 60)),
            plannedMinutes: 30,
            actualSeconds: minutes * 60,
            startPage: startPage,
            finalPage: finalPage
        )
    }

    // MARK: The range

    @Test("The range has one entry per day, ending today", arguments: [
        TrackingViewModel.Range.week, .fortnight, .month,
    ])
    func rangeHasOneEntryPerDay(_ range: TrackingViewModel.Range) {
        let viewModel = makeViewModel(sessions: [])
        viewModel.range = range

        #expect(viewModel.dailyTotals.count == range.days)
        #expect(Self.calendar.isDate(
            viewModel.dailyTotals.last!.day,
            inSameDayAs: Self.today
        ))
    }

    @Test("Days with nothing read are shown as zero, not skipped")
    func emptyDaysAreKept() {
        let viewModel = makeViewModel(sessions: [session(daysAgo: 2, minutes: 30)])

        #expect(viewModel.dailyTotals.count == 7)
        #expect(viewModel.dailyTotals.filter { $0.minutes == 0 }.count == 6)
    }

    @Test("Sessions outside the range are left out")
    func ignoresSessionsOutsideTheRange() {
        let viewModel = makeViewModel(sessions: [
            session(daysAgo: 3, minutes: 20),
            session(daysAgo: 40, minutes: 90),  // long before any range starts
        ])

        #expect(viewModel.totalMinutes == 20)
    }

    @Test("A longer range reaches sessions a shorter one misses")
    func longerRangeReachesFurtherBack() {
        let viewModel = makeViewModel(sessions: [session(daysAgo: 20, minutes: 45)])

        #expect(viewModel.totalMinutes == 0, "20 days ago is outside a 7-day range")

        viewModel.range = .month
        #expect(viewModel.totalMinutes == 45)
    }

    // MARK: Totals

    @Test("Several sessions on the same day are added together")
    func addsUpSessionsWithinADay() {
        let viewModel = makeViewModel(sessions: [
            session(daysAgo: 1, minutes: 10),
            session(daysAgo: 1, minutes: 25),
        ])

        let day = viewModel.dailyTotals.first { $0.minutes > 0 }
        #expect(day?.minutes == 35)
    }

    @Test("Seconds are summed before being turned into minutes")
    func sumsSecondsBeforeConverting() {
        // Three sessions of 40 seconds are two real minutes. Rounding each one on its own
        // would throw all three away.
        let short = (0..<3).map { _ in
            ReadingSession(
                bookID: Book.previewReading.id,
                startedAt: Self.today,
                endedAt: Self.today.addingTimeInterval(40),
                plannedMinutes: 10,
                actualSeconds: 40,
                startPage: 100,
                finalPage: 100
            )
        }

        #expect(makeViewModel(sessions: short).totalMinutes == 2)
    }

    @Test("The total adds up every day in the range")
    func totalsTheWholeRange() {
        let viewModel = makeViewModel(sessions: [
            session(daysAgo: 0, minutes: 15),
            session(daysAgo: 2, minutes: 30),
            session(daysAgo: 5, minutes: 45),
        ])

        #expect(viewModel.totalMinutes == 90)
    }

    // MARK: The average

    @Test("The average divides by every day in the range, not only the ones with reading")
    func averageDividesByTheWholeRange() {
        // 70 minutes spread over two days of a seven-day week is 10 a day, not 35.
        let viewModel = makeViewModel(sessions: [
            session(daysAgo: 1, minutes: 35),
            session(daysAgo: 3, minutes: 35),
        ])

        #expect(viewModel.totalMinutes == 70)
        #expect(viewModel.averageMinutesPerDay == 10)
    }

    @Test("The same reading averages lower over a longer range")
    func averageDropsOverALongerRange() {
        let viewModel = makeViewModel(sessions: [session(daysAgo: 1, minutes: 70)])

        #expect(viewModel.averageMinutesPerDay == 10)

        viewModel.range = .month
        #expect(viewModel.averageMinutesPerDay == 2)
    }

    // MARK: Empty

    @Test("With nothing read, the tab reports empty instead of drawing a flat chart")
    func reportsEmpty() {
        let viewModel = makeViewModel(sessions: [])

        #expect(viewModel.hasNoSessions)
        #expect(viewModel.totalMinutes == 0)
        #expect(viewModel.averageMinutesPerDay == 0)
    }

    @Test("Today is the day the chart marks")
    func marksToday() throws {
        let viewModel = makeViewModel(sessions: [session(daysAgo: 0, minutes: 15)])

        let marked = viewModel.dailyTotals.filter(viewModel.isToday)
        #expect(marked.count == 1)
        #expect(try #require(marked.first).minutes == 15)
    }

    // MARK: The history

    /// `count` sessions, one per day going backwards from today.
    private func sessions(_ count: Int) -> [ReadingSession] {
        (0..<count).map { session(daysAgo: $0, minutes: 10) }
    }

    @Test("The history opens showing five sessions")
    func historyStartsAtFive() {
        let viewModel = makeViewModel(sessions: sessions(6))

        #expect(viewModel.entries.count == 6)
        #expect(viewModel.visibleEntries.count == 5)
        #expect(viewModel.canShowMore)
    }

    @Test("With five or fewer there is nothing more to show")
    func noButtonWhenEverythingFits() {
        let viewModel = makeViewModel(sessions: sessions(5))

        #expect(viewModel.visibleEntries.count == 5)
        #expect(viewModel.canShowMore == false)
    }

    @Test("Showing more adds five, and stops offering once they are all out")
    func showMoreAddsFive() {
        let viewModel = makeViewModel(sessions: sessions(12), books: [.previewReading])
        viewModel.range = .month  // twelve days needs more than a week

        #expect(viewModel.visibleEntries.count == 5)

        viewModel.showMore()
        #expect(viewModel.visibleEntries.count == 10)
        #expect(viewModel.canShowMore)

        viewModel.showMore()
        #expect(viewModel.visibleEntries.count == 12, "Never more rows than there are sessions")
        #expect(viewModel.canShowMore == false)
    }

    @Test("The newest session comes first, whatever order they arrive in")
    func historyIsNewestFirst() {
        let viewModel = makeViewModel(sessions: [
            session(daysAgo: 3, minutes: 10, startPage: 0, finalPage: 30),
            session(daysAgo: 0, minutes: 10, startPage: 0, finalPage: 90),
            session(daysAgo: 1, minutes: 10, startPage: 0, finalPage: 60),
        ])

        #expect(viewModel.entries.map(\.pagesRead) == [90, 60, 30])
    }

    @Test("The history obeys the range, and going back to five is part of changing it")
    func historyFollowsTheRange() {
        let viewModel = makeViewModel(sessions: sessions(12))

        #expect(viewModel.entries.count == 7, "Only the last seven days")

        viewModel.showMore()
        viewModel.range = .month

        #expect(viewModel.entries.count == 12)
        #expect(viewModel.visibleEntries.count == 5, "A new range starts the list over")
    }

    @Test("Pages read are the difference between the two pages")
    func pagesReadIsTheDifference() throws {
        let viewModel = makeViewModel(sessions: [
            session(daysAgo: 0, minutes: 10, startPage: 120, finalPage: 152),
        ])

        #expect(try #require(viewModel.entries.first).pagesRead == 32)
    }

    @Test("Correcting the page backwards counts as nothing read, never as negative")
    func pagesReadNeverGoNegative() throws {
        let viewModel = makeViewModel(sessions: [
            session(daysAgo: 0, minutes: 10, startPage: 200, finalPage: 180),
        ])

        #expect(try #require(viewModel.entries.first).pagesRead == 0)
    }

    @Test("A session of a deleted book leaves the list but stays in the total")
    func deletedBooksLeaveTheHistoryOnly() {
        let deleted = Book(title: "Gone", genre: .novel, pageCount: 100)
        let viewModel = makeViewModel(
            sessions: [
                session(daysAgo: 0, minutes: 20),
                session(daysAgo: 1, minutes: 25, book: deleted),
            ],
            books: [.previewReading]  // the deleted one is not in the catalog any more
        )

        #expect(viewModel.entries.count == 1)
        #expect(viewModel.totalMinutes == 45, "Time read is time read, listed or not")
    }

    @Test("Each row carries its book, so it can be drawn like every other book row")
    func entriesCarryTheirBook() throws {
        let viewModel = makeViewModel(sessions: [session(daysAgo: 0, minutes: 20)])

        let entry = try #require(viewModel.entries.first)
        #expect(entry.book == .previewReading)
        #expect(entry.minutes == 20)
    }

    @Test("With nothing in the range there is no history to draw")
    func emptyHistory() {
        let viewModel = makeViewModel(sessions: [session(daysAgo: 40, minutes: 30)])

        #expect(viewModel.visibleEntries.isEmpty)
        #expect(viewModel.canShowMore == false)
    }
}
