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

    /// The durations offered, in minutes. Kept here rather than in the view so tests can rely on
    /// them. `0` stands for a free session — the duration sheet shows it as "Free" rather than
    /// "0 min", and everywhere else in this type treats it as no plan at all.
    static let offeredMinutes = [10, 15, 30, 0]

    @Published private(set) var phase: Phase
    /// Time left before the plan runs out. Meaningless for a free session — always `0` — read
    /// ``elapsedTime`` instead.
    @Published private(set) var remaining: TimeInterval
    /// Time read so far. What a free session's clock counts up to; unused by a planned one.
    @Published private(set) var elapsedTime: TimeInterval
    @Published var finalPageText = ""

    let book: Book

    private var stored: StoredSession
    private let repository: BookRepository
    private let sessionRepository: ReadingSessionRepository
    private let notifications: any SessionNotificationScheduling
    private let store: any ActiveSessionStoring
    private let now: () -> Date
    /// Seconds read, captured the moment the page was asked for — not the moment it is actually
    /// answered. Filling in a page can take a while; without this, a slow answer would credit
    /// that time as reading, and a planned session could overshoot its own plan.
    private var accumulatedAtFinish: TimeInterval?

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
        elapsedTime = stored.elapsed(at: moment)

        // A session whose time ran out while the app was closed is over: it goes straight to
        // asking for the page, counting the full planned time it was given. A free session never
        // triggers this — it has no planned time to have run out of.
        if stored.isExpired(at: moment) {
            phase = .askingPage
        } else {
            phase = stored.isPaused ? .paused : .running
        }

        // Pre-filled with where the reader already was, since most sessions move a few pages on.
        finalPageText = String(book.currentPage)

        if phase == .askingPage {
            freezeForFinish()
        }
    }

    var plannedMinutes: Int { stored.plannedMinutes }
    var isFree: Bool { stored.isFree }

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

        let moment = now()
        remaining = stored.remaining(at: moment)
        elapsedTime = stored.elapsed(at: moment)

        // A free session has no remaining time to hit zero: it only ends when the reader says so.
        if !stored.isFree, remaining == 0 {
            askForPage()
        }
    }

    /// Brings this ViewModel's published state back in line with a `StoredSession` that changed
    /// from outside it — namely `ActiveSessionController` pausing a free session left running in
    /// the background too long. Without this, the screen would keep counting a clock the store
    /// no longer agrees with.
    func reload(from updated: StoredSession) {
        stored = updated
        let moment = now()
        remaining = stored.remaining(at: moment)
        elapsedTime = stored.elapsed(at: moment)
        phase = stored.isPaused ? .paused : .running
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

        // A free session has no time to schedule an alert for.
        if !stored.isFree {
            notifications.scheduleSessionEnd(in: remaining, bookTitle: book.title)
        }
    }

    /// Ends the session early. The time already read still counts.
    func finishEarly() {
        guard phase == .running || phase == .paused else { return }
        askForPage()
    }

    private func askForPage() {
        phase = .askingPage
        freezeForFinish()
        // One last read of the clock, for the ring behind the sheet to land on the exact number
        // being credited rather than whatever the last per-second tick happened to catch.
        let moment = now()
        remaining = stored.remaining(at: moment)
        elapsedTime = stored.elapsed(at: moment)
    }

    /// Snapshots the seconds read so far and stops the pending alert — but, deliberately,
    /// touches neither `stored` nor `store`. The session is only actually finalized by ``save()``:
    /// leaving the persisted copy alone means that abandoning this screen — backgrounding, or the
    /// app being killed, without ever tapping "save" — leaves the session exactly as it was
    /// (still running or paused), recoverable and ticking again on the next launch, rather than
    /// stuck forever with a clock that no longer moves and no way to start a new one in its
    /// place.
    ///
    /// Capped at the plan for a planned session, so filling in the page slowly never credits more
    /// than what was asked. A free session has no plan to cap against — capping at
    /// `plannedDuration` there would mean capping at zero.
    private func freezeForFinish() {
        accumulatedAtFinish = stored.isFree ? elapsed : min(elapsed, stored.plannedDuration)
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

    /// Backs out of "what page are you on?" without saving anything.
    ///
    /// `freezeForFinish()` never touched `stored`, so the underlying session is exactly as it
    /// was before it was asked for — this just re-derives the screen's phase from it, the same
    /// way ``reload(from:)`` does, and re-arms the alert a resumed planned session needs.
    ///
    /// If the plan had already run out on its own, this puts the reader right back where they
    /// started: `refresh()` will ask again within the second, honestly, because there really is
    /// no time left — not a bug, just nothing left to cancel out of.
    func cancelFinishing() {
        guard phase == .askingPage else { return }

        accumulatedAtFinish = nil
        let moment = now()
        remaining = stored.remaining(at: moment)
        elapsedTime = stored.elapsed(at: moment)
        phase = stored.isPaused ? .paused : .running

        if phase == .running, !stored.isFree {
            notifications.scheduleSessionEnd(in: remaining, bookTitle: book.title)
        }
    }

    /// True once something is typed that is not a valid page, so the screen can explain why
    /// saving is blocked instead of leaving a dead button.
    var showsPageOutOfRange: Bool {
        !finalPageText.isEmpty && finalPage == nil
    }

    /// Stores the session and moves the book's bookmark. Returns `false` if anything failed, so
    /// the sheet stays open rather than losing the time that was just read.
    func save() -> Bool {
        guard let finalPage else { return false }

        // `accumulatedAtFinish` is set by `freezeForFinish()`, which every path into
        // `.askingPage` goes through — the fallback only guards against a future call site that
        // forgets to.
        let actualSeconds = accumulatedAtFinish ?? (stored.isFree ? elapsed : min(elapsed, stored.plannedDuration))

        let session = ReadingSession(
            bookID: book.id,
            startedAt: stored.startedAt,
            endedAt: now(),
            plannedMinutes: stored.plannedMinutes,
            actualSeconds: Int(actualSeconds.rounded()),
            // Where the book stood when this session opened: `book` is the snapshot taken then,
            // and nothing but a session moves the bookmark.
            startPage: book.currentPage,
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
