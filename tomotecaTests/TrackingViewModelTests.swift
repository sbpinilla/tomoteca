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

    private func makeViewModel(sessions: [ReadingSession]) -> TrackingViewModel {
        TrackingViewModel(
            repository: FakeReadingSessionRepository(seeded: sessions),
            calendar: Self.calendar,
            now: { Self.today }
        )
    }

    /// A session of `minutes` minutes, `daysAgo` days before the fixed today.
    private func session(daysAgo: Int, minutes: Int) -> ReadingSession {
        let day = Self.calendar.date(
            byAdding: .day,
            value: -daysAgo,
            to: Self.calendar.startOfDay(for: Self.today)
        )!
        let started = day.addingTimeInterval(20 * 3600)

        return ReadingSession(
            bookID: Book.previewReading.id,
            startedAt: started,
            endedAt: started.addingTimeInterval(TimeInterval(minutes * 60)),
            plannedMinutes: 30,
            actualSeconds: minutes * 60,
            finalPage: 100
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
}
