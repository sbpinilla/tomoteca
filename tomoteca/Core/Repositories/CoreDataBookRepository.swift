//
//  CoreDataBookRepository.swift
//  tomoteca
//

import Combine
import CoreData

/// `BookRepository` backed by Core Data.
///
/// Owns the mapping between `BookEntity` and `Book`; no managed object escapes this file.
///
/// Main-actor isolated on purpose: it reads through `viewContext` and its subject is fed from
/// the main queue, so subscribers are already on the main thread and the publisher needs no
/// `receive(on:)`. That hop would cost a frame, during which a populated list would render its
/// empty state first.
@MainActor
final class CoreDataBookRepository: BookRepository {

    private let context: NSManagedObjectContext
    private let subject = CurrentValueSubject<[Book], Never>([])
    private var saveObserver: (any NSObjectProtocol)?

    /// Takes the controller rather than a context so that no layer above this one has to
    /// import Core Data just to wire the app together.
    init(persistence: PersistenceController) {
        self.context = persistence.container.viewContext

        // Re-read after any save so the list stays live once books can be added or deleted.
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

    var books: AnyPublisher<[Book], Never> {
        subject.eraseToAnyPublisher()
    }

    private func reload() {
        let request = NSFetchRequest<BookEntity>(entityName: "BookEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            subject.send(try context.fetch(request).compactMap(Self.makeBook))
        } catch {
            // A failed read leaves the last good value in place rather than blanking the list.
            assertionFailure("Failed to fetch books: \(error)")
        }
    }

    /// Maps a stored entity to the domain type.
    ///
    /// Returns `nil` for a row missing the fields the domain treats as required. Those are
    /// non-optional in the model, so this only trips on a store corrupted by hand or by a bad
    /// migration — in which case skipping the row beats crashing the list.
    private static func makeBook(from entity: BookEntity) -> Book? {
        guard
            let id = entity.id,
            let title = entity.title,
            let createdAt = entity.createdAt,
            let genre = entity.genreRawValue.flatMap(Genre.init(rawValue:)),
            let status = BookStatus(rawValue: entity.statusRawValue)
        else {
            return nil
        }

        return Book(
            id: id,
            title: title,
            author: entity.author,
            genre: genre,
            pageCount: Int(entity.pageCount),
            currentPage: Int(entity.currentPage),
            status: status,
            coverImageData: entity.coverImageData,
            createdAt: createdAt
        )
    }
}
