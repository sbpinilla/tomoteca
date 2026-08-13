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

    init(
        bookRepository: BookRepository,
        sessionRepository: ReadingSessionRepository,
        notifications: any SessionNotificationScheduling,
        store: any ActiveSessionStoring,
        now: @escaping () -> Date = Date.init
    ) {
        self.bookRepository = bookRepository
        self.sessionRepository = sessionRepository
        self.notifications = notifications
        self.store = store
        self.now = now

        bookRepository.books
            .assign(to: \.books, on: self)
            .store(in: &cancellables)

        restore()
    }

    /// Picks up a session left behind by a previous launch, unless it is past saving.
    func restore() {
        guard let saved = store.load() else { return }

        // Long overdue: asking which page it reached would only get a guess, and the banner
        // would sit there for good.
        if saved.isStale(at: now()) {
            discard()
            return
        }

        stored = saved
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
        notifications.scheduleSessionEnd(in: session.plannedDuration, bookTitle: book.title)
        sessionViewModel = makeViewModel()
        isPresenting = true
    }

    /// Prepares the ViewModel for a session recovered from storage, once its book is known.
    func prepareViewModelIfNeeded() {
        guard sessionViewModel == nil else { return }
        sessionViewModel = makeViewModel()
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
    }

    /// Drops a session without recording it, and takes its pending alert with it.
    func discard() {
        stored = nil
        sessionViewModel = nil
        isPresenting = false
        store.clear()
        notifications.cancelScheduledSessionEnd()
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
