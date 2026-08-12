//
//  ReadingSessionViewModel.swift
//  tomoteca
//

import Combine
import Foundation

/// Runs a reading session: the countdown, the pause, and the page that closes it.
///
/// **The clock is never counted, only read.** Elapsed time is always the difference between
/// timestamps, so a tick missed while the app is in the background changes nothing: coming back
/// to the foreground and asking again gives the right answer. A view that accumulated one
/// second per tick would silently under-count exactly when someone is reading a paper book with
/// the phone locked.
@MainActor
final class ReadingSessionViewModel: ObservableObject {

    enum Phase: Equatable {
        case running
        case paused
        /// Time is up or the reader stopped: the page is being asked for.
        case askingPage
        /// Saved and done.
        case finished
    }

    /// The durations offered. Kept here rather than in the view so tests can rely on them.
    static let offeredMinutes = [10, 15, 30]

    @Published private(set) var phase: Phase = .running
    @Published private(set) var remaining: TimeInterval
    @Published var finalPageText = ""

    let book: Book
    let plannedMinutes: Int

    private let repository: BookRepository
    private let sessionRepository: ReadingSessionRepository
    private let notifications: any SessionNotificationScheduling
    private let now: () -> Date

    private let plannedDuration: TimeInterval
    private let startedAt: Date
    /// Time already banked from previous run segments, in seconds.
    private var accumulated: TimeInterval = 0
    /// When the current run segment began, or `nil` while paused.
    private var segmentStartedAt: Date?

    init(
        book: Book,
        plannedMinutes: Int,
        repository: BookRepository,
        sessionRepository: ReadingSessionRepository,
        notifications: any SessionNotificationScheduling,
        now: @escaping () -> Date = Date.init
    ) {
        self.book = book
        self.plannedMinutes = plannedMinutes
        self.repository = repository
        self.sessionRepository = sessionRepository
        self.notifications = notifications
        self.now = now

        plannedDuration = TimeInterval(plannedMinutes * 60)
        remaining = plannedDuration
        startedAt = now()
        segmentStartedAt = startedAt

        // Pre-filled with where the reader already was, since most sessions move a few pages on.
        finalPageText = String(book.currentPage)

        notifications.scheduleSessionEnd(in: plannedDuration, bookTitle: book.title)
    }

    // MARK: Time

    /// Seconds actually read so far.
    var elapsed: TimeInterval {
        guard let segmentStartedAt else { return accumulated }
        return accumulated + now().timeIntervalSince(segmentStartedAt)
    }

    /// How much of the planned time has gone, from 0 to 1, for the ring.
    var progress: Double {
        guard plannedDuration > 0 else { return 0 }
        return min(1, max(0, elapsed / plannedDuration))
    }

    /// Recomputes the countdown from the clock. Called on every tick and whenever the app comes
    /// back to the foreground, which is what makes background time survive.
    func refresh() {
        guard phase == .running else { return }

        remaining = max(0, plannedDuration - elapsed)

        if remaining == 0 {
            askForPage()
        }
    }

    // MARK: Controls

    func pause() {
        guard phase == .running else { return }

        accumulated = elapsed
        segmentStartedAt = nil
        phase = .paused

        // The alert would fire at a time that no longer means anything.
        notifications.cancelScheduledSessionEnd()
    }

    func resume() {
        guard phase == .paused else { return }

        segmentStartedAt = now()
        phase = .running
        notifications.scheduleSessionEnd(in: remaining, bookTitle: book.title)
    }

    /// Ends the session early. The time already read still counts.
    func finishEarly() {
        guard phase == .running || phase == .paused else { return }
        askForPage()
    }

    private func askForPage() {
        accumulated = elapsed
        segmentStartedAt = nil
        remaining = max(0, plannedDuration - accumulated)
        phase = .askingPage
        notifications.cancelScheduledSessionEnd()
    }

    // MARK: Closing

    /// The typed page, if it is a page this book actually has.
    var finalPage: Int? {
        guard
            let page = Int(finalPageText.trimmingCharacters(in: .whitespaces)),
            page >= 0,
            page <= book.pageCount
        else {
            return nil
        }
        return page
    }

    var canSave: Bool { finalPage != nil }

    /// True once something is typed that is not a valid page, so the screen can explain why
    /// saving is blocked instead of leaving a dead button.
    var showsPageOutOfRange: Bool {
        !finalPageText.isEmpty && finalPage == nil
    }

    /// Stores the session and moves the book's bookmark. Returns `false` if anything failed, so
    /// the sheet stays open rather than losing the time that was just read.
    func save() -> Bool {
        guard let finalPage else { return false }

        let session = ReadingSession(
            bookID: book.id,
            startedAt: startedAt,
            endedAt: now(),
            plannedMinutes: plannedMinutes,
            actualSeconds: Int(elapsed.rounded()),
            finalPage: finalPage
        )

        var updated = book
        updated.currentPage = finalPage

        do {
            try sessionRepository.add(session)
            try repository.update(updated)
        } catch {
            return false
        }

        phase = .finished
        return true
    }
}

/// Lets a plain minute count drive `fullScreenCover(item:)`, which needs an identifiable value.
extension Int: @retroactive Identifiable {
    public var id: Int { self }
}
