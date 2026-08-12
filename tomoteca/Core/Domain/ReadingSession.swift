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
    /// The page the reader had reached when the session closed.
    let finalPage: Int

    init(
        id: UUID = UUID(),
        bookID: UUID,
        startedAt: Date,
        endedAt: Date,
        plannedMinutes: Int,
        actualSeconds: Int,
        finalPage: Int
    ) {
        self.id = id
        self.bookID = bookID
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.plannedMinutes = plannedMinutes
        self.actualSeconds = actualSeconds
        self.finalPage = finalPage
    }

    /// The day this session belongs to, for grouping in the tracking chart.
    func day(in calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: startedAt)
    }
}
