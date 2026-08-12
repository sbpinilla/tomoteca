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

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // TODO: surface this to the user instead of crashing before shipping.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
