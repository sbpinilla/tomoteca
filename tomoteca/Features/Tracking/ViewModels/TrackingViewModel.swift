//
//  TrackingViewModel.swift
//  tomoteca
//

import Combine
import Foundation

/// How much was read each day over a recent stretch of time.
@MainActor
final class TrackingViewModel: ObservableObject {

    /// How far back the chart looks. The range always ends today.
    enum Range: Int, CaseIterable, Identifiable {
        case week = 7
        case fortnight = 15
        case month = 30

        var id: Int { rawValue }
        var days: Int { rawValue }
    }

    /// One bar: a day and the minutes read in it.
    struct DailyTotal: Identifiable, Equatable {
        let day: Date
        let minutes: Int

        var id: Date { day }
    }

    /// One line of the history: a session with the book it belongs to already resolved.
    ///
    /// Carries the whole book rather than a copy of its title, so the row can show a cover and an
    /// author the same way the trunk and the in-progress list do, without this growing a field
    /// every time the row shows one more thing.
    struct Entry: Identifiable, Equatable {
        /// The session's id: the same book appears on many rows.
        let id: UUID
        let book: Book
        let date: Date
        let pagesRead: Int
        let minutes: Int
    }

    /// How many entries the history shows at a time, and how many each tap adds.
    static let pageSize = 5

    @Published var range: Range = .week {
        // A different range is a different list; carrying the expansion over would land the
        // reader halfway down a history they have not scrolled.
        didSet { visibleEntryCount = Self.pageSize }
    }
    @Published private(set) var sessions: [ReadingSession] = []
    @Published private(set) var books: [Book] = []
    @Published private(set) var visibleEntryCount = TrackingViewModel.pageSize

    private let calendar: Calendar
    private let now: () -> Date
    private var cancellables = Set<AnyCancellable>()

    init(
        repository: ReadingSessionRepository,
        bookRepository: BookRepository,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init
    ) {
        self.calendar = calendar
        self.now = now

        repository.sessions
            .assign(to: \.sessions, on: self)
            .store(in: &cancellables)

        // Only for the titles: the chart and the totals never need a book.
        bookRepository.books
            .assign(to: \.books, on: self)
            .store(in: &cancellables)
    }

    /// One entry per day in the range, oldest first, **including days with nothing read**.
    ///
    /// Skipping the empty days would flatter the picture: seven bars in a row read as a steady
    /// week even when they are seven scattered days out of three months.
    var dailyTotals: [DailyTotal] {
        let seconds = secondsByDay()

        return days.map { day in
            DailyTotal(day: day, minutes: minutes(fromSeconds: seconds[day] ?? 0))
        }
    }

    /// Minutes read across the whole range.
    var totalMinutes: Int {
        minutes(fromSeconds: secondsByDay().values.reduce(0, +))
    }

    /// Minutes per day, averaged over **every** day in the range.
    ///
    /// Dividing only by the days that had a session would not be an average, just a flattering
    /// number: reading twice a week would report the same as reading daily.
    var averageMinutesPerDay: Int {
        guard !days.isEmpty else { return 0 }
        return totalMinutes / days.count
    }

    var hasNoSessions: Bool { dailyTotals.allSatisfy { $0.minutes == 0 } }

    // MARK: History

    /// Every session in the range that can be named, newest first.
    ///
    /// Sessions whose book has been deleted are left out. They still count towards the chart and
    /// the totals — time read is time read (#17) — but a row with no book title tells nobody
    /// anything, which is the one place where the list and the chart deliberately disagree.
    var entries: [Entry] {
        let catalog = Dictionary(books.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let window = Set(days)

        return sessions
            .filter { window.contains($0.day(in: calendar)) }
            .sorted { $0.startedAt > $1.startedAt }
            .compactMap { session in
                guard let book = catalog[session.bookID] else { return nil }

                return Entry(
                    id: session.id,
                    book: book,
                    date: session.startedAt,
                    pagesRead: session.pagesRead,
                    minutes: minutes(fromSeconds: session.actualSeconds)
                )
            }
    }

    /// The slice on screen.
    var visibleEntries: [Entry] { Array(entries.prefix(visibleEntryCount)) }

    var canShowMore: Bool { entries.count > visibleEntryCount }

    /// Shows the next handful. Only ever grows: nothing takes rows away again.
    func showMore() {
        visibleEntryCount += Self.pageSize
    }

    /// True for the last bar, so the chart can mark today without the reader parsing the axis.
    func isToday(_ total: DailyTotal) -> Bool {
        calendar.isDate(total.day, inSameDayAs: now())
    }

    /// Every day in the range, oldest first, ending today.
    private var days: [Date] {
        let today = calendar.startOfDay(for: now())
        return (0..<range.days)
            .compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
            .reversed()
    }

    /// Seconds read per day, for the days inside the range.
    private func secondsByDay() -> [Date: Int] {
        let window = Set(days)

        return sessions.reduce(into: [:]) { totals, session in
            let day = session.day(in: calendar)
            guard window.contains(day) else { return }
            totals[day, default: 0] += session.actualSeconds
        }
    }

    /// Seconds are summed first and converted once: rounding each session on its own would drop
    /// three forty-second sessions, which are two real minutes.
    private func minutes(fromSeconds seconds: Int) -> Int {
        Int((Double(seconds) / 60).rounded())
    }
}
