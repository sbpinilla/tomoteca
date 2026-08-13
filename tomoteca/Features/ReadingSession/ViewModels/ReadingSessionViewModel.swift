//
//  ReadingSessionViewModel.swift
//  tomoteca
//

import Combine
import Foundation

/// Runs a reading session: the countdown, the pause, and the page that closes it.
///
/// **The clock is never counted, only read.** Elapsed time is always the difference between
/// timestamps, so a tick missed while the app is in the background changes nothing — and, since
/// those timestamps are written to ``ActiveSessionStoring``, neither does the app being killed
/// outright. A view that accumulated one second per tick would silently under-count exactly when
/// someone is reading a paper book with the phone locked.
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

    @Published private(set) var phase: Phase
    @Published private(set) var remaining: TimeInterval
    @Published var finalPageText = ""

    let book: Book

    private var stored: StoredSession
    private let repository: BookRepository
    private let sessionRepository: ReadingSessionRepository
    private let notifications: any SessionNotificationScheduling
    private let store: any ActiveSessionStoring
    private let now: () -> Date

    /// Resumes — or starts — a session from its stored state.
    ///
    /// There is no separate "start" path: starting writes a `StoredSession` and comes through
    /// here, so a fresh session and one recovered after a relaunch follow the same code.
    init(
        book: Book,
        stored: StoredSession,
        repository: BookRepository,
        sessionRepository: ReadingSessionRepository,
        notifications: any SessionNotificationScheduling,
        store: any ActiveSessionStoring,
        now: @escaping () -> Date = Date.init
    ) {
        self.book = book
        self.stored = stored
        self.repository = repository
        self.sessionRepository = sessionRepository
        self.notifications = notifications
        self.store = store
        self.now = now

        let moment = now()
        remaining = stored.remaining(at: moment)

        // A session whose time ran out while the app was closed is over: it goes straight to
        // asking for the page, counting the full planned time it was given.
        if stored.isExpired(at: moment) {
            phase = .askingPage
        } else {
            phase = stored.isPaused ? .paused : .running
        }

        // Pre-filled with where the reader already was, since most sessions move a few pages on.
        finalPageText = String(book.currentPage)

        if phase == .askingPage {
            closeOut()
        }
    }

    var plannedMinutes: Int { stored.plannedMinutes }

    // MARK: Time

    /// Seconds actually read so far.
    var elapsed: TimeInterval { stored.elapsed(at: now()) }

    /// How much of the planned time has gone, from 0 to 1, for the ring.
    var progress: Double {
        guard stored.plannedDuration > 0 else { return 0 }
        return min(1, max(0, elapsed / stored.plannedDuration))
    }

    /// Recomputes the countdown from the clock. Called on every tick and whenever the app comes
    /// back to the foreground, which is what makes background time survive.
    func refresh() {
        guard phase == .running else { return }

        remaining = stored.remaining(at: now())

        if remaining == 0 {
            askForPage()
        }
    }

    // MARK: Controls

    func pause() {
        guard phase == .running else { return }

        stored.accumulated = elapsed
        stored.segmentStartedAt = nil
        store.save(stored)
        phase = .paused

        // The alert would fire at a time that no longer means anything.
        notifications.cancelScheduledSessionEnd()
    }

    func resume() {
        guard phase == .paused else { return }

        stored.segmentStartedAt = now()
        store.save(stored)
        phase = .running
        notifications.scheduleSessionEnd(in: remaining, bookTitle: book.title)
    }

    /// Ends the session early. The time already read still counts.
    func finishEarly() {
        guard phase == .running || phase == .paused else { return }
        askForPage()
    }

    private func askForPage() {
        phase = .askingPage
        closeOut()
    }

    /// Freezes the clock and stops the pending alert. The stored session stays until the page
    /// is answered, so killing the app at this point still leaves something to come back to.
    private func closeOut() {
        stored.accumulated = min(elapsed, stored.plannedDuration)
        stored.segmentStartedAt = nil
        store.save(stored)
        remaining = stored.remaining(at: now())
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
            startedAt: stored.startedAt,
            endedAt: now(),
            plannedMinutes: stored.plannedMinutes,
            actualSeconds: Int(stored.accumulated.rounded()),
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

        store.clear()
        phase = .finished
        return true
    }
}

/// Lets a plain minute count drive `fullScreenCover(item:)`, which needs an identifiable value.
extension Int: @retroactive Identifiable {
    public var id: Int { self }
}
