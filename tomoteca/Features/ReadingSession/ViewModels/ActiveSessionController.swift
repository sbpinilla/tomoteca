//
//  ActiveSessionController.swift
//  tomoteca
//

import Combine
import Foundation

/// Owns the one session that can be in progress, for the whole app.
///
/// It lives at the root rather than inside a book's detail screen, and that placement is the
/// fix: with the session held by whichever detail happened to open it, nothing stopped a second
/// one starting from another book, and killing the app lost the first while its notification
/// carried on regardless.
@MainActor
final class ActiveSessionController: ObservableObject {

    /// The session in progress, or `nil` when there is none.
    @Published private(set) var stored: StoredSession?
    /// Whether its screen is on top. The session can exist without being shown — that is what
    /// the banner is for.
    @Published var isPresenting = false
    /// The running session's ViewModel, built once.
    ///
    /// Held here rather than made on demand: a fresh one per render would throw away the phase
    /// and whatever page had been typed, every time anything on screen changed.
    @Published private(set) var sessionViewModel: ReadingSessionViewModel?

    private var books: [Book] = []

    private let bookRepository: BookRepository
    private let sessionRepository: ReadingSessionRepository
    private let notifications: any SessionNotificationScheduling
    private let store: any ActiveSessionStoring
    private let now: () -> Date
    private var cancellables = Set<AnyCancellable>()
    private var liveActivity: (any ReadingSessionLiveActivityUpdating)?
    /// Builds the Live Activity controller, or `nil` on a phone too old for one. A `let` closure
    /// rather than always constructing `ReadingSessionLiveActivityController` directly, so a
    /// test can substitute a fake and see what this type asks of it without touching real
    /// ActivityKit.
    private let makeLiveActivity: () -> (any ReadingSessionLiveActivityUpdating)?

    init(
        bookRepository: BookRepository,
        sessionRepository: ReadingSessionRepository,
        notifications: any SessionNotificationScheduling,
        store: any ActiveSessionStoring,
        now: @escaping () -> Date = Date.init,
        makeLiveActivity: @escaping () -> (any ReadingSessionLiveActivityUpdating)? = ActiveSessionController.defaultLiveActivity
    ) {
        self.bookRepository = bookRepository
        self.sessionRepository = sessionRepository
        self.notifications = notifications
        self.store = store
        self.now = now
        self.makeLiveActivity = makeLiveActivity

        bookRepository.books
            .assign(to: \.books, on: self)
            .store(in: &cancellables)

        restore()
    }

    private static func defaultLiveActivity() -> (any ReadingSessionLiveActivityUpdating)? {
        if #available(iOS 16.2, *) {
            return ReadingSessionLiveActivityController()
        }
        return nil
    }

    /// How long a free session can sit with the app backgrounded before it is paused on its own.
    ///
    /// A planned session needs nothing like this — it already stops crediting time once it hits
    /// its plan. A free session has no plan to stop at, so left running by accident it would
    /// otherwise credit however long the phone sat untouched as time spent reading.
    static let freeSessionAutoPauseAfter: TimeInterval = 30 * 60

    /// Picks up a session left behind by a previous launch, unless it is past saving.
    func restore() {
        guard var saved = store.load() else { return }

        // Long overdue: asking which page it reached would only get a guess, and the banner
        // would sit there for good.
        if saved.isStale(at: now()) {
            discard()
            return
        }

        // The app backgrounding is what precedes it being killed, so a free session left running
        // when it was, and reopened only now, goes through the same check `appDidBecomeActive()`
        // does for a plain background-and-return.
        if pauseIfLeftRunningTooLong(&saved) {
            store.save(saved)
        }

        stored = saved
    }

    /// Marks the moment, so a free session left running can be told apart from one genuinely
    /// being read the whole time the app was away.
    func appDidEnterBackground() {
        guard var current = stored, current.isFree, !current.isPaused else { return }

        current.backgroundedAt = now()
        stored = current
        store.save(current)
    }

    /// Pauses a free session that sat backgrounded past ``freeSessionAutoPauseAfter``, crediting
    /// it only up to the moment it left the foreground — not the moment it came back.
    func appDidBecomeActive() {
        guard var current = stored else { return }

        if pauseIfLeftRunningTooLong(&current) {
            store.save(current)
            sessionViewModel?.reload(from: current)
        }

        stored = current
    }

    /// Pauses `session` in place if it is a free one that was left running past the threshold,
    /// and always clears its background marker — leaving a stale one behind would confuse the
    /// next check. Returns whether anything changed, so callers only write to storage when there
    /// was something to write.
    private func pauseIfLeftRunningTooLong(_ session: inout StoredSession) -> Bool {
        guard session.isFree, let backgroundedAt = session.backgroundedAt else { return false }

        if !session.isPaused, now().timeIntervalSince(backgroundedAt) > Self.freeSessionAutoPauseAfter {
            session.accumulated = session.elapsed(at: backgroundedAt)
            session.segmentStartedAt = nil
        }
        session.backgroundedAt = nil
        return true
    }

    /// The book the session belongs to, once the catalog has it.
    var book: Book? {
        guard let stored else { return nil }
        return books.first { $0.id == stored.bookID }
    }

    var hasActiveSession: Bool { stored != nil }

    /// True when the planned time has already run out, so the banner can say so.
    var isExpired: Bool {
        stored?.isExpired(at: now()) ?? false
    }

    var remaining: TimeInterval {
        stored?.remaining(at: now()) ?? 0
    }

    var isFree: Bool { stored?.isFree ?? false }

    /// Time read so far. What the banner shows for a free session, in place of `remaining`.
    var elapsed: TimeInterval {
        stored?.elapsed(at: now()) ?? 0
    }

    /// Begins a session, unless one is already running — in which case the existing one is
    /// brought forward instead of quietly replaced.
    func start(book: Book, minutes: Int) {
        guard stored == nil else {
            isPresenting = true
            return
        }

        let session = StoredSession(
            bookID: book.id,
            plannedMinutes: minutes,
            startedAt: now(),
            accumulated: 0,
            segmentStartedAt: now()
        )

        store.save(session)
        stored = session

        // A free session has no end time to schedule an alert for.
        if !session.isFree {
            notifications.scheduleSessionEnd(in: session.plannedDuration, bookTitle: book.title)
        }

        sessionViewModel = makeViewModel()
        observeLiveActivityUpdates()
        startLiveActivity(book: book, stored: session)
        isPresenting = true
    }

    /// Prepares the ViewModel for a session recovered from storage, once its book is known.
    ///
    /// Deliberately does **not** start a *new* Live Activity: one already exists from whenever
    /// the session actually began, and `Activity.request` cannot be called for a session that
    /// is not new — the activity survives on its own regardless. It does reconnect to that
    /// existing activity, so a pause or resume from here still has something to update.
    func prepareViewModelIfNeeded() {
        guard sessionViewModel == nil else { return }
        sessionViewModel = makeViewModel()
        observeLiveActivityUpdates()
        attachLiveActivity()
    }

    private func makeViewModel() -> ReadingSessionViewModel? {
        guard let stored, let book else { return nil }

        return ReadingSessionViewModel(
            book: book,
            stored: stored,
            repository: bookRepository,
            sessionRepository: sessionRepository,
            notifications: notifications,
            store: store,
            now: now
        )
    }

    /// The session was saved: nothing left to come back to.
    func finish() {
        stored = nil
        sessionViewModel = nil
        isPresenting = false
        store.clear()
        endLiveActivity()
    }

    /// Drops a session without recording it, and takes its pending alert with it.
    func discard() {
        stored = nil
        sessionViewModel = nil
        isPresenting = false
        store.clear()
        notifications.cancelScheduledSessionEnd()
        endLiveActivity()
    }

    // MARK: Live Activity

    /// Pauses and resumes are the only phase changes worth telling the Island about — a session
    /// that is simply running counts itself down on the system's own clock, and re-pushing an
    /// update on every one-second tick would be exactly the busywork `Text(timerInterval:)`
    /// exists to avoid.
    private func observeLiveActivityUpdates() {
        sessionViewModel?.$phase
            .dropFirst()
            .sink { [weak self] _ in
                guard let self, let stored = self.store.load() else { return }
                self.updateLiveActivity(stored)
            }
            .store(in: &cancellables)
    }

    private func startLiveActivity(book: Book, stored: StoredSession) {
        let controller = makeLiveActivity()
        controller?.start(book: book, stored: stored)
        liveActivity = controller
    }

    private func attachLiveActivity() {
        guard let stored else { return }
        let controller = makeLiveActivity()
        controller?.attach(stored: stored)
        liveActivity = controller
    }

    private func updateLiveActivity(_ stored: StoredSession) {
        liveActivity?.update(stored: stored)
    }

    private func endLiveActivity() {
        liveActivity?.end()
        liveActivity = nil
    }
}

#if DEBUG
extension ActiveSessionController {

    /// A controller with nothing running, for previews.
    static var preview: ActiveSessionController {
        ActiveSessionController(
            bookRepository: PreviewBookRepository.populated,
            sessionRepository: PreviewReadingSessionRepository(),
            notifications: PreviewNotificationScheduler(),
            store: InMemoryActiveSessionStore()
        )
    }
}
#endif
