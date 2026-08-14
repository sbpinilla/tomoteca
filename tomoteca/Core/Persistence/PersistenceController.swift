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
        backfillSessionStartPages()
    }

    /// Reconstructs the starting page of sessions recorded before it was stored.
    ///
    /// Each book's sessions are walked oldest first, and each one starts where the previous one
    /// ended — which is what the starting page has always been. The first session of a book
    /// starts at page 0: there is nothing earlier to chain from, and inside the app that is where
    /// a book begins. A book imported with progress already made is the case this gets wrong, and
    /// it is unknowable from what was stored.
    ///
    /// Not private, unlike the other two: this one reconstructs a number rather than copying one
    /// across, and it runs over reading that is already on the phone, so it is worth a test.
    func backfillSessionStartPages() {
        let context = container.viewContext
        let request = NSFetchRequest<ReadingSessionEntity>(entityName: "ReadingSessionEntity")
        request.predicate = NSPredicate(format: "startPage == nil")
        request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: true)]

        guard let pending = try? context.fetch(request), !pending.isEmpty else { return }

        var lastPage: [UUID: Int] = [:]

        for session in pending {
            guard let bookID = session.bookID ?? session.book?.id else {
                session.startPage = 0
                continue
            }

            session.startPage = NSNumber(value: lastPage[bookID] ?? 0)
            lastPage[bookID] = Int(session.finalPage)
        }

        try? context.save()
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
