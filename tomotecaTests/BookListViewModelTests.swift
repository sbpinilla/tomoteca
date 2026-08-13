//
//  BookListViewModelTests.swift
//  tomotecaTests
//

import Foundation
import Testing
@testable import tomoteca

@MainActor
struct BookListViewModelTests {

    /// A defaults suite of its own per test, so a remembered shelf never leaks into the next.
    private func makeDefaults() -> UserDefaults {
        let name = "tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    private func makeViewModel(
        books: [Book] = [],
        defaults: UserDefaults? = nil
    ) -> BookListViewModel {
        BookListViewModel(
            repository: FakeBookRepository(books: books),
            defaults: defaults ?? makeDefaults()
        )
    }

    /// A book placed on a shelf at a given moment, for testing order.
    private func book(
        _ title: String,
        status: BookStatus = .owned,
        registered: TimeInterval,
        arrived: TimeInterval? = nil
    ) -> Book {
        Book(
            title: title,
            genre: .novel,
            pageCount: 100,
            status: status,
            createdAt: Date(timeIntervalSince1970: registered),
            statusChangedAt: arrived.map(Date.init(timeIntervalSince1970:))
        )
    }

    // MARK: The catalog

    @Test("Starts empty when the repository has nothing")
    func startsEmpty() {
        let viewModel = makeViewModel()

        #expect(viewModel.books.isEmpty)
        #expect(viewModel.isEmpty)
    }

    @Test("Takes the catalog the repository publishes")
    func mirrorsTheRepository() {
        let repository = FakeBookRepository()
        let viewModel = BookListViewModel(repository: repository, defaults: makeDefaults())

        repository.emit(Book.previewCatalog)

        #expect(viewModel.books.count == Book.previewCatalog.count)
        #expect(viewModel.isEmpty == false)
    }

    @Test("Keeps up with later changes instead of holding the first catalog")
    func followsLaterChanges() {
        let repository = FakeBookRepository()
        let viewModel = BookListViewModel(repository: repository, defaults: makeDefaults())

        repository.emit([.previewOwned])
        repository.emit([.previewOwned, .previewReading])

        #expect(viewModel.books.count == 2)
    }

    @Test("Reports empty again when every book is gone")
    func reportsEmptyAfterRemoval() {
        let repository = FakeBookRepository()
        let viewModel = BookListViewModel(repository: repository, defaults: makeDefaults())

        repository.emit(Book.previewCatalog)
        repository.emit([])

        #expect(viewModel.isEmpty)
    }

    // MARK: Shelves

    @Test("A shelf shows only its own books")
    func aShelfShowsOnlyItsOwn() {
        let viewModel = makeViewModel(books: Book.previewCatalog)

        viewModel.shelf = .reading

        #expect(viewModel.visibleBooks.map(\.status) == [.reading])
    }

    @Test("There is one shelf per status, and no way to see them all at once")
    func offersOneShelfPerStatus() {
        #expect(makeViewModel().shelves == BookStatus.allCases)
    }

    @Test("Each shelf reports how many books it holds")
    func countsBooksPerShelf() {
        let viewModel = makeViewModel(books: Book.previewCatalog)

        #expect(viewModel.count(of: .wishlist) == 1)
        #expect(viewModel.count(of: .owned) == 1)
        #expect(viewModel.count(of: .reading) == 1)
        #expect(viewModel.count(of: .finished) == 1)
    }

    @Test("The count ignores the search, so it still says what is over there")
    func countIgnoresTheSearch() {
        let viewModel = makeViewModel(books: Book.previewCatalog)

        viewModel.searchText = "nothing matches this"

        #expect(viewModel.count(of: .owned) == 1)
    }

    @Test("A shelf with nothing on it is not the same as an empty library")
    func distinguishesAnEmptyShelf() {
        let viewModel = makeViewModel(books: [.previewOwned])

        viewModel.shelf = .finished

        #expect(viewModel.isShelfEmpty)
        #expect(viewModel.isEmpty == false)
        #expect(viewModel.hasNoResults == false, "Nothing is being searched for")
    }

    @Test("The trunk opens on the bought shelf the first time")
    func opensOnBoughtByDefault() {
        #expect(makeViewModel().shelf == .owned)
    }

    @Test("The chosen shelf is remembered for next time")
    func remembersTheChosenShelf() {
        let defaults = makeDefaults()

        let first = makeViewModel(books: Book.previewCatalog, defaults: defaults)
        first.shelf = .finished

        let second = makeViewModel(books: Book.previewCatalog, defaults: defaults)
        #expect(second.shelf == .finished)
    }

    // MARK: Order within a shelf

    @Test("The book that arrived last is shown first")
    func newestArrivalComesFirst() {
        let viewModel = makeViewModel(books: [
            book("Antiguo", registered: 1_000),
            book("Reciente", registered: 9_000),
        ])

        #expect(viewModel.visibleBooks.map(\.title) == ["Reciente", "Antiguo"])
    }

    @Test("Arrival beats registration: a book bought today leads a shelf it joined late")
    func arrivalBeatsRegistration() {
        let viewModel = makeViewModel(books: [
            // Registered recently and never moved.
            book("Añadido ayer", registered: 5_000),
            // Registered long ago, moved onto this shelf a moment ago.
            book("Movido hoy", registered: 1_000, arrived: 9_000),
        ])

        #expect(viewModel.visibleBooks.map(\.title) == ["Movido hoy", "Añadido ayer"])
    }

    @Test("A book that never moved sorts by when it was registered")
    func neverMovedSortsByRegistration() {
        let viewModel = makeViewModel(books: [
            book("Primero", registered: 1_000),
            book("Segundo", registered: 5_000),
        ])

        #expect(viewModel.visibleBooks.map(\.title) == ["Segundo", "Primero"])
    }

    @Test("Order is kept per shelf: moving a book does not disturb the one it left")
    func orderIsPerShelf() {
        let viewModel = makeViewModel(books: [
            book("Comprado viejo", status: .owned, registered: 1_000),
            book("Comprado nuevo", status: .owned, registered: 8_000),
            book("Leyendo", status: .reading, registered: 500, arrived: 9_999),
        ])

        #expect(viewModel.visibleBooks.map(\.title) == ["Comprado nuevo", "Comprado viejo"])

        viewModel.shelf = .reading
        #expect(viewModel.visibleBooks.map(\.title) == ["Leyendo"])
    }

    // MARK: Search

    @Test("Searching narrows the shelf by title")
    func searchesByTitle() {
        let viewModel = makeViewModel(books: Book.previewCatalog)
        viewModel.shelf = .owned

        viewModel.searchText = "Sapiens"

        #expect(viewModel.visibleBooks.map(\.title) == ["Sapiens"])
    }

    @Test("Searching also looks at the author")
    func searchesByAuthor() {
        let viewModel = makeViewModel(books: Book.previewCatalog)
        viewModel.shelf = .wishlist

        viewModel.searchText = "Andy Weir"

        #expect(viewModel.visibleBooks.map(\.title) == ["Project Hail Mary"])
    }

    @Test("Searching ignores case and accents", arguments: ["garcía", "GARCIA", "garcia", "Márquez", "marquez"])
    func searchIgnoresCaseAndAccents(_ query: String) {
        let viewModel = makeViewModel(books: Book.previewCatalog)
        viewModel.shelf = .reading

        viewModel.searchText = query

        #expect(viewModel.visibleBooks.map(\.title) == ["Cien años de soledad"])
    }

    @Test("Blank search text shows the whole shelf")
    func blankSearchShowsTheShelf() {
        let viewModel = makeViewModel(books: Book.previewCatalog)
        viewModel.shelf = .owned

        viewModel.searchText = "   "

        #expect(viewModel.visibleBooks.count == viewModel.count(of: .owned))
    }

    @Test("Search only reaches the shelf on screen")
    func searchStaysWithinTheShelf() {
        let viewModel = makeViewModel(books: Book.previewCatalog)
        viewModel.shelf = .reading

        viewModel.searchText = "Sapiens"  // exists, but it is a bought book

        #expect(viewModel.visibleBooks.isEmpty)
        #expect(viewModel.hasNoResults)
    }

    @Test("A search matching nothing is reported as no results, not as an empty shelf")
    func distinguishesNoResultsFromAnEmptyShelf() {
        let viewModel = makeViewModel(books: Book.previewCatalog)
        viewModel.shelf = .owned

        viewModel.searchText = "nothing matches this"

        #expect(viewModel.hasNoResults)
        #expect(viewModel.isShelfEmpty == false, "The shelf has a book; the search is what is empty")
        #expect(viewModel.isEmpty == false)
    }

    // MARK: Delete

    @Test("Deleting removes the book from the store")
    func deletesABook() {
        let repository = FakeBookRepository(books: Book.previewCatalog)
        let viewModel = BookListViewModel(repository: repository, defaults: makeDefaults())

        viewModel.delete(.previewOwned)

        #expect(repository.deletedIDs == [Book.previewOwned.id])
        #expect(viewModel.books.contains { $0.id == Book.previewOwned.id } == false)
    }

    @Test("A swipe resolves to the row that was swiped, not the same offset in the catalog")
    func resolvesTheSwipedRow() {
        let viewModel = makeViewModel(books: Book.previewCatalog)
        viewModel.shelf = .reading

        // Offset 0 of the *visible* shelf, which is not offset 0 of the catalog.
        let swiped = viewModel.book(atOffsets: IndexSet(integer: 0))

        #expect(swiped?.id == Book.previewReading.id)
    }

    @Test("A swipe on a row that is no longer there resolves to nothing")
    func resolvesNothingOutOfRange() {
        let viewModel = makeViewModel(books: [.previewOwned])

        #expect(viewModel.book(atOffsets: IndexSet(integer: 5)) == nil)
    }
}
