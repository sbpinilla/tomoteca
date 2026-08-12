//
//  BookDetailViewModelTests.swift
//  tomotecaTests
//

import Foundation
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

    // MARK: Cover

    @Test("A cover can be added to a book that has none")
    func addsACover() {
        let (viewModel, repository) = makeViewModel(for: .previewWishlist)
        #expect(viewModel.book.coverImageData == nil)

        viewModel.setCover(Data([0x01, 0x02]))

        #expect(viewModel.book.coverImageData == Data([0x01, 0x02]))
        #expect(repository.updateCount == 1)
    }

    @Test("A new cover replaces the previous one")
    func replacesTheCover() {
        let (viewModel, _) = makeViewModel(for: .previewReading)

        viewModel.setCover(Data([0xAA]))

        #expect(viewModel.book.coverImageData == Data([0xAA]))
    }

    @Test("Removing the cover leaves the rest of the book untouched")
    func removesTheCover() {
        let (viewModel, _) = makeViewModel(for: .previewReading)

        viewModel.removeCover()

        #expect(viewModel.book.coverImageData == nil)
        #expect(viewModel.book.title == Book.previewReading.title)
        #expect(viewModel.book.status == .reading)
    }

    @Test("A cover can be added at any point in the book's life, not only when it is registered")
    func coverCanBeAddedAfterAdvancing() {
        let (viewModel, _) = makeViewModel(for: .previewWishlist)

        viewModel.advanceStatus()
        viewModel.setCover(Data([0x07]))

        #expect(viewModel.book.status == .owned)
        #expect(viewModel.book.coverImageData == Data([0x07]))
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
