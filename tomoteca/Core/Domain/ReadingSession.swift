//
//  ReadingSession.swift
//  tomoteca
//

import Foundation

/// One stretch of reading, already finished.
///
/// Sessions are the history the tracking tab is built from, and they are never deleted or
/// edited: what was read was read.
struct ReadingSession: Identifiable, Equatable, Hashable, Sendable {

    let id: UUID
    let bookID: UUID
    let startedAt: Date
    let endedAt: Date
    /// What was asked for: 10, 15 or 30 minutes.
    let plannedMinutes: Int
    /// What was actually read, in seconds. Smaller than planned when the session was ended
    /// early, and stored in seconds so short sessions do not round away to nothing.
    let actualSeconds: Int
    /// The page the reader was on when the session began.
    ///
    /// Always the previous session's final page for that book, but recorded rather than derived:
    /// a book imported with progress already made has no previous session to chain from, and
    /// deriving it would count everything read before the app as read in its first session.
    let startPage: Int
    /// The page the reader had reached when the session closed.
    let finalPage: Int

    init(
        id: UUID = UUID(),
        bookID: UUID,
        startedAt: Date,
        endedAt: Date,
        plannedMinutes: Int,
        actualSeconds: Int,
        startPage: Int,
        finalPage: Int
    ) {
        self.id = id
        self.bookID = bookID
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.plannedMinutes = plannedMinutes
        self.actualSeconds = actualSeconds
        self.startPage = startPage
        self.finalPage = finalPage
    }

    /// How much of the book the session moved through.
    ///
    /// Never negative: correcting the page downwards at the end of a session is a correction,
    /// not reading in reverse.
    var pagesRead: Int { max(0, finalPage - startPage) }

    /// The day this session belongs to, for grouping in the tracking chart.
    func day(in calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: startedAt)
    }
}
