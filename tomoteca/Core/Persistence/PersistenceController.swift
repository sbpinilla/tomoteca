//
//  PersistenceController.swift
//  tomoteca
//

import CoreData

/// Owns the Core Data stack. Everything persisted by the app goes through this container.
struct PersistenceController {

    /// The app's store.
    ///
    /// A debug run started with `-useInMemoryStore` gets a throwaway one instead, so UI tests
    /// begin from a clean library and cannot leak books into each other — or into the
    /// simulator a developer is using by hand.
    static let shared: PersistenceController = {
        #if DEBUG
        let isEphemeral = CommandLine.arguments.contains("-useInMemoryStore")
        return PersistenceController(inMemory: isEphemeral)
        #else
        return PersistenceController()
        #endif
    }()

    /// In-memory stack for previews and tests. Seeded with sample books from Hito 1 on.
    @MainActor
    static let preview = PersistenceController(inMemory: true)

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "tomoteca")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        // Stated rather than left to the defaults: the model has already changed once under a
        // store holding real books, and this is the line that keeps them.
        container.persistentStoreDescriptions.first?.shouldMigrateStoreAutomatically = true
        container.persistentStoreDescriptions.first?.shouldInferMappingModelAutomatically = true

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // TODO: surface this to the user instead of crashing before shipping.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true

        backfillSessionBookIDs()
        backfillStatusChangedAt()
    }

    /// Gives books written before the field existed a date to sort by.
    ///
    /// Their real move dates are gone, so their creation date stands in: not when they actually
    /// changed shelves, but the best available, and it preserves the order they already had.
    private func backfillStatusChangedAt() {
        let context = container.viewContext
        let request = NSFetchRequest<BookEntity>(entityName: "BookEntity")
        request.predicate = NSPredicate(format: "statusChangedAt == nil")

        guard let pending = try? context.fetch(request), !pending.isEmpty else { return }

        for book in pending {
            book.statusChangedAt = book.createdAt
        }

        try? context.save()
    }

    /// Fills in the `bookID` that older sessions do not have.
    ///
    /// An inferred migration adds the column but leaves it empty, and the relationship it can be
    /// recovered from is about to stop being reliable — that is the whole point of the change.
    /// Runs once: after the first pass there is nothing left to find.
    private func backfillSessionBookIDs() {
        let context = container.viewContext
        let request = NSFetchRequest<ReadingSessionEntity>(entityName: "ReadingSessionEntity")
        request.predicate = NSPredicate(format: "bookID == nil")

        guard let orphans = try? context.fetch(request), !orphans.isEmpty else { return }

        for session in orphans {
            session.bookID = session.book?.id
        }

        try? context.save()
    }
}
