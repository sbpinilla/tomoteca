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
    func seedSampleDataIfNeeded() {
        let context = container.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BookEntity")
        request.fetchLimit = 1

        guard (try? context.count(for: request)) == 0 else { return }

        for book in Book.previewCatalog {
            let entity = BookEntity(context: context)
            entity.id = book.id
            entity.title = book.title
            entity.author = book.author
            entity.genreRawValue = book.genre.rawValue
            entity.pageCount = Int32(book.pageCount)
            entity.currentPage = Int32(book.currentPage)
            entity.statusRawValue = book.status.rawValue
            entity.createdAt = book.createdAt
        }

        do {
            try context.save()
        } catch {
            assertionFailure("Failed to seed sample data: \(error)")
        }
    }
}
#endif
