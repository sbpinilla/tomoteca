//
//  PersistenceController.swift
//  tomoteca
//

import CoreData

/// Owns the Core Data stack. Everything persisted by the app goes through this container.
struct PersistenceController {

    static let shared = PersistenceController()

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
