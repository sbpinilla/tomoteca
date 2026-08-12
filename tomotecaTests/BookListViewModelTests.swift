//
//  BookListViewModelTests.swift
//  tomotecaTests
//

import Combine
import Testing
@testable import tomoteca

/// Repository fake: lets a test push catalogs without a store behind it.
private final class FakeBookRepository: BookRepository {

    private let subject = CurrentValueSubject<[Book], Never>([])

    var books: AnyPublisher<[Book], Never> {
        subject.eraseToAnyPublisher()
    }

    func emit(_ books: [Book]) {
        subject.send(books)
    }
}

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
}
