//
//  BookDetailViewModelTests.swift
//  tomotecaTests
//

import Testing
@testable import tomoteca

@MainActor
struct BookDetailViewModelTests {

    private func makeViewModel(for book: Book) -> (BookDetailViewModel, FakeBookRepository) {
        let repository = FakeBookRepository(books: [book])
        return (BookDetailViewModel(book: book, repository: repository), repository)
    }

    @Test("Offers the next status in the cycle")
    func offersTheNextStatus() {
        let (viewModel, _) = makeViewModel(for: .previewOwned)
        #expect(viewModel.nextStatus == .reading)
    }

    @Test("A finished book has nowhere left to go")
    func finishedBookOffersNothing() {
        let (viewModel, _) = makeViewModel(for: .previewFinished)
        #expect(viewModel.nextStatus == nil)
    }

    @Test("Advancing moves the book one step and stores it")
    func advancingStoresTheNewStatus() {
        let (viewModel, repository) = makeViewModel(for: .previewOwned)

        viewModel.advanceStatus()

        #expect(viewModel.book.status == .reading)
        #expect(repository.updateCount == 1)
    }

    @Test("Advancing walks the whole cycle one step at a time")
    func advancingWalksTheCycle() {
        let wishlisted = Book(title: "A", genre: .novel, pageCount: 100, status: .wishlist)
        let (viewModel, _) = makeViewModel(for: wishlisted)

        viewModel.advanceStatus()
        #expect(viewModel.book.status == .owned)

        viewModel.advanceStatus()
        #expect(viewModel.book.status == .reading)

        viewModel.advanceStatus()
        #expect(viewModel.book.status == .finished)
    }

    @Test("A finished book cannot be advanced or reopened")
    func finishedBookStaysPut() {
        let (viewModel, repository) = makeViewModel(for: .previewFinished)

        viewModel.advanceStatus()

        #expect(viewModel.book.status == .finished)
        #expect(repository.updateCount == 0, "Nothing should be written for a finished book")
    }

    @Test("Advancing keeps everything except the status")
    func advancingPreservesTheRestOfTheBook() {
        let (viewModel, _) = makeViewModel(for: .previewReading)

        viewModel.advanceStatus()

        #expect(viewModel.book.title == Book.previewReading.title)
        #expect(viewModel.book.currentPage == Book.previewReading.currentPage)
        #expect(viewModel.book.pageCount == Book.previewReading.pageCount)
        #expect(viewModel.book.genre == Book.previewReading.genre)
    }

    @Test("The sheet closes once the status has moved")
    func sheetClosesAfterAdvancing() {
        let (viewModel, _) = makeViewModel(for: .previewOwned)
        viewModel.isChangingStatus = true

        viewModel.advanceStatus()

        #expect(viewModel.isChangingStatus == false)
    }

    @Test("The sheet stays open when the write fails, so the change is not lost silently")
    func sheetStaysOpenOnFailure() {
        let (viewModel, repository) = makeViewModel(for: .previewOwned)
        repository.errorToThrow = StubError()
        viewModel.isChangingStatus = true

        viewModel.advanceStatus()

        #expect(viewModel.isChangingStatus)
        #expect(viewModel.book.status == .owned)
    }

    @Test("Picks up a change made elsewhere instead of holding its own copy")
    func followsChangesFromOtherScreens() throws {
        let repository = FakeBookRepository(books: [.previewOwned])
        let viewModel = BookDetailViewModel(book: .previewOwned, repository: repository)

        var elsewhere = Book.previewOwned
        elsewhere.currentPage = 120
        try repository.update(elsewhere)

        #expect(viewModel.book.currentPage == 120)
    }
}
