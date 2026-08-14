//
//  InProgressViewModelTests.swift
//  tomotecaTests
//

import Foundation
import Testing
@testable import tomoteca

@MainActor
struct InProgressViewModelTests {

    private func makeViewModel(
        books: [Book]
    ) -> (InProgressViewModel, FakeBookRepository) {
        let repository = FakeBookRepository(books: books)
        return (InProgressViewModel(repository: repository), repository)
    }

    private func reading(_ title: String) -> Book {
        Book(title: title, genre: .novel, pageCount: 300, status: .reading)
    }

    @Test("Only books being read reach this tab")
    func listsOnlyBooksBeingRead() {
        let (viewModel, _) = makeViewModel(books: [
            .previewReading, .previewOwned, .previewWishlist, .previewFinished,
        ])

        #expect(viewModel.books.map(\.id) == [Book.previewReading.id])
    }

    // MARK: The single book

    @Test("With one book being read, that book is the one the tab can offer")
    func offersTheOnlyBook() {
        let (viewModel, _) = makeViewModel(books: [.previewReading, .previewOwned])

        #expect(viewModel.onlyBook?.id == Book.previewReading.id)
    }

    @Test("With two books there is a choice to make, so the tab offers neither")
    func offersNothingWithTwo() {
        let (viewModel, _) = makeViewModel(books: [reading("A"), reading("B")])

        #expect(viewModel.books.count == 2)
        #expect(viewModel.onlyBook == nil)
    }

    @Test("With nothing being read there is nothing to offer")
    func offersNothingWhenEmpty() {
        let (viewModel, _) = makeViewModel(books: [.previewOwned, .previewWishlist])

        #expect(viewModel.isEmpty)
        #expect(viewModel.onlyBook == nil)
    }

    @Test("A book that is only owned does not count towards the one being read")
    func ignoresBooksOnOtherShelves() {
        let (viewModel, _) = makeViewModel(books: [
            .previewReading, .previewOwned, .previewFinished,
        ])

        #expect(viewModel.onlyBook?.id == Book.previewReading.id)
    }

    @Test("Finishing one of two books leaves the other one on offer")
    func followsTheCatalogDownToOne() throws {
        let first = reading("A")
        let second = reading("B")
        let (viewModel, repository) = makeViewModel(books: [first, second])

        #expect(viewModel.onlyBook == nil)

        var finished = first
        finished.status = .finished
        try repository.update(finished)

        #expect(viewModel.onlyBook?.id == second.id, "The tab follows the catalog, not its own copy")
    }

    @Test("Starting a second book takes the offer away again")
    func stopsOfferingWhenASecondArrives() throws {
        let (viewModel, repository) = makeViewModel(books: [.previewReading, .previewOwned])

        #expect(viewModel.onlyBook != nil)

        var alsoReading = Book.previewOwned
        alsoReading.status = .reading
        try repository.update(alsoReading)

        #expect(viewModel.onlyBook == nil)
    }
}
