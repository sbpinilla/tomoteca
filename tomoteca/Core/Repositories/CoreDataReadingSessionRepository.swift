//
//  CoreDataReadingSessionRepository.swift
//  tomoteca
//

import Combine
import CoreData
import Foundation

/// `ReadingSessionRepository` backed by Core Data.
///
/// Main-actor isolated for the same reason as the book repository: it reads through
/// `viewContext` and publishes from the main queue, so subscribers need no hop.
@MainActor
final class CoreDataReadingSessionRepository: ReadingSessionRepository {

    private let context: NSManagedObjectContext
    private let subject = CurrentValueSubject<[ReadingSession], Never>([])
    private var saveObserver: (any NSObjectProtocol)?

    init(persistence: PersistenceController) {
        self.context = persistence.container.viewContext

        saveObserver = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reload()
        }

        reload()
    }

    deinit {
        if let saveObserver {
            NotificationCenter.default.removeObserver(saveObserver)
        }
    }

    var sessions: AnyPublisher<[ReadingSession], Never> {
        subject.eraseToAnyPublisher()
    }

    func add(_ session: ReadingSession) throws {
        guard let book = try bookEntity(withID: session.bookID) else {
            throw RepositoryError.bookNotFound
        }

        let entity = ReadingSessionEntity(context: context)
        entity.id = session.id
        // Both: the relationship for navigating from a book, and the id so the session still
        // knows what it belonged to once that book is deleted.
        entity.book = book
        entity.bookID = session.bookID
        entity.startedAt = session.startedAt
        entity.endedAt = session.endedAt
        entity.plannedMinutes = Int32(session.plannedMinutes)
        entity.actualSeconds = Int32(session.actualSeconds)
        entity.finalPage = Int32(session.finalPage)

        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }

        reload()
    }

    private func bookEntity(withID id: UUID) throws -> BookEntity? {
        let request = NSFetchRequest<BookEntity>(entityName: "BookEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func reload() {
        let request = NSFetchRequest<ReadingSessionEntity>(entityName: "ReadingSessionEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]

        do {
            subject.send(try context.fetch(request).compactMap(Self.makeSession))
        } catch {
            assertionFailure("Failed to fetch reading sessions: \(error)")
        }
    }

    private static func makeSession(from entity: ReadingSessionEntity) -> ReadingSession? {
        guard
            let id = entity.id,
            // The stored id first: the relationship is empty for a session whose book is gone,
            // and that session still counts towards the time read.
            let bookID = entity.bookID ?? entity.book?.id,
            let startedAt = entity.startedAt,
            let endedAt = entity.endedAt
        else {
            return nil
        }

        return ReadingSession(
            id: id,
            bookID: bookID,
            startedAt: startedAt,
            endedAt: endedAt,
            plannedMinutes: Int(entity.plannedMinutes),
            actualSeconds: Int(entity.actualSeconds),
            finalPage: Int(entity.finalPage)
        )
    }
}

#if DEBUG
/// In-memory session repository for previews.
final class PreviewReadingSessionRepository: ReadingSessionRepository {

    private let subject: CurrentValueSubject<[ReadingSession], Never>

    init(sessions: [ReadingSession] = []) {
        subject = CurrentValueSubject(sessions)
    }

    var sessions: AnyPublisher<[ReadingSession], Never> {
        subject.eraseToAnyPublisher()
    }

    func add(_ session: ReadingSession) throws {
        subject.send([session] + subject.value)
    }
}
#endif
