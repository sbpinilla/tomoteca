//
//  ReadingSessionRepository.swift
//  tomoteca
//

import Combine

/// Access to the reading history.
///
/// There is no update and no delete on purpose: a session is a record of something that
/// happened, and the tracking tab is only trustworthy if it cannot be rewritten.
protocol ReadingSessionRepository {

    /// Every session recorded, newest first. Re-emits on every change.
    var sessions: AnyPublisher<[ReadingSession], Never> { get }

    /// Stores a finished session.
    func add(_ session: ReadingSession) throws
}
