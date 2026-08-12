//
//  CoreDataBookRepositoryTests.swift
//  tomotecaTests
//

import Combine
import CoreData
import Testing
@testable import tomoteca

@MainActor
struct CoreDataBookRepositoryTests {

    /// A fresh in-memory stack per test, so no test can see another's books.
    private func makeStack() -> PersistenceController {
        PersistenceController(inMemory: true)
    }

    private func insert(_ book: Book, into persistence: PersistenceController) throws {
        let context = persistence.container.viewContext
        let entity = BookEntity(context: context)
        entity.id = book.id
        entity.title = book.title
        entity.author = book.author
        entity.genreRawValue = book.genre.rawValue
        entity.pageCount = Int32(book.pageCount)
        entity.currentPage = Int32(book.currentPage)
        entity.statusRawValue = book.status.rawValue
        entity.createdAt = book.createdAt
        try context.save()
    }

    private func firstValue(of repository: BookRepository) -> [Book] {
        var received: [Book] = []
        var cancellables = Set<AnyCancellable>()
        repository.books
            .sink { received = $0 }
            .store(in: &cancellables)
        return received
    }

    @Test("An empty store yields an empty catalog")
    func emptyStoreYieldsNoBooks() {
        let repository = CoreDataBookRepository(persistence: makeStack())
        #expect(firstValue(of: repository).isEmpty)
    }

    @Test("Stored books come back mapped to the domain type")
    func mapsStoredBooksToDomain() throws {
        let persistence = makeStack()
        try insert(.previewReading, into: persistence)

        let books = firstValue(of: CoreDataBookRepository(persistence: persistence))

        #expect(books.count == 1)
        let book = try #require(books.first)
        #expect(book.title == Book.previewReading.title)
        #expect(book.author == Book.previewReading.author)
        #expect(book.genre == .novel)
        #expect(book.status == .reading)
        #expect(book.pageCount == 340)
        #expect(book.currentPage == 210)
    }

    @Test("The catalog is ordered newest first")
    func ordersNewestFirst() throws {
        let persistence = makeStack()
        // Inserted oldest-first on purpose: the order must come from the sort, not the writes.
        try insert(.previewWishlist, into: persistence)
        try insert(.previewOwned, into: persistence)
        try insert(.previewReading, into: persistence)

        let titles = firstValue(of: CoreDataBookRepository(persistence: persistence)).map(\.title)

        #expect(titles == [
            Book.previewReading.title,
            Book.previewOwned.title,
            Book.previewWishlist.title,
        ])
    }

    @Test("A book saved later reaches subscribers already listening")
    func republishesAfterASave() throws {
        let persistence = makeStack()
        let repository = CoreDataBookRepository(persistence: persistence)

        var received: [[Book]] = []
        var cancellables = Set<AnyCancellable>()
        repository.books
            .sink { received.append($0) }
            .store(in: &cancellables)

        try insert(.previewOwned, into: persistence)

        #expect(received.last?.count == 1)
    }

    @Test("A row with an unknown genre is skipped instead of breaking the list")
    func skipsRowsWithUnreadableFields() throws {
        let persistence = makeStack()
        let context = persistence.container.viewContext

        let entity = BookEntity(context: context)
        entity.id = UUID()
        entity.title = "Corrupt"
        entity.genreRawValue = "a_genre_that_no_longer_exists"
        entity.pageCount = 100
        entity.statusRawValue = 0
        entity.createdAt = Date()
        try context.save()

        #expect(firstValue(of: CoreDataBookRepository(persistence: persistence)).isEmpty)
    }
}
