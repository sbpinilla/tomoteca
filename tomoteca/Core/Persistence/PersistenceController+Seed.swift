//
//  PersistenceController+Seed.swift
//  tomoteca
//

#if DEBUG
import CoreData

extension PersistenceController {

    /// Launch argument that fills an empty store with sample books.
    ///
    /// Kept behind a flag so a normal run still starts empty and shows the empty state — which
    /// is what a new user actually sees, and the thing most likely to go unnoticed otherwise.
    static let seedArgument = "-seedSampleData"

    /// Inserts the sample catalog, but only when the store has no books yet.
    ///
    /// Writes through the repository rather than building entities here: the mapping from
    /// domain to store belongs in one place, and a second copy of it drifts the moment a field
    /// is added — as happened with the cover.
    @MainActor
    func seedSampleDataIfNeeded() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BookEntity")
        request.fetchLimit = 1

        guard (try? container.viewContext.count(for: request)) == 0 else { return }

        let repository = CoreDataBookRepository(persistence: self)

        do {
            // Oldest first, so the newest-first ordering comes out matching the samples.
            for book in Book.previewCatalog.reversed() {
                try repository.add(book)
            }
        } catch {
            assertionFailure("Failed to seed sample data: \(error)")
        }
    }
}
#endif
