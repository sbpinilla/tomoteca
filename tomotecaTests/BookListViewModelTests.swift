//
//  BookListViewModelTests.swift
//  tomotecaTests
//

import Foundation
import Testing
@testable import tomoteca

@MainActor
struct BookListViewModelTests {

    @Test("Starts empty when the repository has nothing")
    func startsEmpty() {
        let viewModel = BookListViewModel(repository: FakeBookRepository())

        #expect(viewModel.books.isEmpty)
        #expect(viewModel.isEmpty)
    }

    @Test("Takes the catalog the repository publishes")
    func mirrorsTheRepository() {
        let repository = FakeBookRepository()
        let viewModel = BookListViewModel(repository: repository)

        repository.emit(Book.previewCatalog)

        #expect(viewModel.books.count == Book.previewCatalog.count)
        #expect(viewModel.isEmpty == false)
    }

    @Test("Keeps up with later changes instead of holding the first catalog")
    func followsLaterChanges() {
        let repository = FakeBookRepository()
        let viewModel = BookListViewModel(repository: repository)

        repository.emit([.previewOwned])
        repository.emit([.previewOwned, .previewReading])

        #expect(viewModel.books.count == 2)
    }

    @Test("Reports empty again when every book is gone")
    func reportsEmptyAfterRemoval() {
        let repository = FakeBookRepository()
        let viewModel = BookListViewModel(repository: repository)

        repository.emit(Book.previewCatalog)
        repository.emit([])

        #expect(viewModel.isEmpty)
    }

    // MARK: Search

    @Test("Searching narrows the list by title")
    func searchesByTitle() {
        let viewModel = BookListViewModel(repository: FakeBookRepository(books: Book.previewCatalog))

        viewModel.searchText = "Sapiens"

        #expect(viewModel.visibleBooks.map(\.title) == ["Sapiens"])
    }

    @Test("Searching also looks at the author")
    func searchesByAuthor() {
        let viewModel = BookListViewModel(repository: FakeBookRepository(books: Book.previewCatalog))

        viewModel.searchText = "Andy Weir"

        #expect(viewModel.visibleBooks.map(\.title) == ["Project Hail Mary"])
    }

    @Test("Searching ignores case and accents", arguments: ["garcía", "GARCIA", "garcia", "Márquez", "marquez"])
    func searchIgnoresCaseAndAccents(_ query: String) {
        let viewModel = BookListViewModel(repository: FakeBookRepository(books: Book.previewCatalog))

        viewModel.searchText = query

        #expect(viewModel.visibleBooks.map(\.title) == ["Cien años de soledad"])
    }

    @Test("Blank search text shows everything")
    func blankSearchShowsEverything() {
        let viewModel = BookListViewModel(repository: FakeBookRepository(books: Book.previewCatalog))

        viewModel.searchText = "   "

        #expect(viewModel.visibleBooks.count == Book.previewCatalog.count)
    }

    @Test("A search matching nothing is reported as no results, not as an empty library")
    func distinguishesNoResultsFromEmptyLibrary() {
        let viewModel = BookListViewModel(repository: FakeBookRepository(books: Book.previewCatalog))

        viewModel.searchText = "nothing matches this"

        #expect(viewModel.visibleBooks.isEmpty)
        #expect(viewModel.hasNoResults)
        #expect(viewModel.isEmpty == false, "The library still has books; only the search is empty")
    }

    // MARK: Filter

    @Test("Filtering by status narrows the list")
    func filtersByStatus() {
        let viewModel = BookListViewModel(repository: FakeBookRepository(books: Book.previewCatalog))

        viewModel.filter = .status(.reading)

        #expect(viewModel.visibleBooks.map(\.status) == [.reading])
    }

    @Test("The 'all' filter shows every book")
    func allFilterShowsEverything() {
        let viewModel = BookListViewModel(repository: FakeBookRepository(books: Book.previewCatalog))

        viewModel.filter = .all

        #expect(viewModel.visibleBooks.count == Book.previewCatalog.count)
    }

    @Test("Search runs inside the filtered subset, not over the whole library")
    func searchAndFilterCombine() {
        let viewModel = BookListViewModel(repository: FakeBookRepository(books: Book.previewCatalog))

        viewModel.filter = .status(.reading)
        viewModel.searchText = "Sapiens"  // exists, but it is a bought book

        #expect(viewModel.visibleBooks.isEmpty)
        #expect(viewModel.hasNoResults)
    }

    // MARK: Delete

    @Test("Deleting removes the book from the store")
    func deletesABook() {
        let repository = FakeBookRepository(books: Book.previewCatalog)
        let viewModel = BookListViewModel(repository: repository)

        viewModel.delete(.previewOwned)

        #expect(repository.deletedIDs == [Book.previewOwned.id])
        #expect(viewModel.books.contains { $0.id == Book.previewOwned.id } == false)
    }

    @Test("A swipe resolves to the row that was swiped, even with a filter narrowing the list")
    func resolvesTheSwipedRowWhileFiltered() {
        let viewModel = BookListViewModel(repository: FakeBookRepository(books: Book.previewCatalog))
        viewModel.filter = .status(.reading)

        // Offset 0 of the *visible* list, which is not offset 0 of the catalog.
        let swiped = viewModel.book(atOffsets: IndexSet(integer: 0))

        #expect(swiped?.id == Book.previewReading.id)
    }

    @Test("A swipe on a row that is no longer there resolves to nothing")
    func resolvesNothingOutOfRange() {
        let viewModel = BookListViewModel(repository: FakeBookRepository(books: [.previewOwned]))

        #expect(viewModel.book(atOffsets: IndexSet(integer: 5)) == nil)
    }
}
