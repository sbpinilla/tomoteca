//
//  BookFormViewModelTests.swift
//  tomotecaTests
//

import Testing
@testable import tomoteca

@MainActor
struct BookFormViewModelTests {

    private func makeViewModel() -> (BookFormViewModel, FakeBookRepository) {
        let repository = FakeBookRepository()
        return (BookFormViewModel(repository: repository), repository)
    }

    // MARK: Validation

    @Test("An untouched form cannot be saved")
    func emptyFormIsNotSavable() {
        let (viewModel, _) = makeViewModel()
        #expect(viewModel.canSave == false)
    }

    @Test("Every required field has to be filled before saving")
    func requiresTitleGenreAndPages() {
        let (viewModel, _) = makeViewModel()

        viewModel.title = "Sapiens"
        #expect(viewModel.canSave == false)

        viewModel.genre = .history
        #expect(viewModel.canSave == false)

        viewModel.pageCountText = "512"
        #expect(viewModel.canSave)
    }

    @Test("A title of only spaces does not count as filled in")
    func whitespaceTitleIsNotEnough() {
        let (viewModel, _) = makeViewModel()
        viewModel.title = "   "
        viewModel.genre = .novel
        viewModel.pageCountText = "100"

        #expect(viewModel.canSave == false)
    }

    @Test("Page counts that are not a positive number are rejected", arguments: ["", "0", "-5", "abc", "12.5"])
    func rejectsUnusablePageCounts(_ input: String) {
        let (viewModel, _) = makeViewModel()
        viewModel.title = "Sapiens"
        viewModel.genre = .history
        viewModel.pageCountText = input

        #expect(viewModel.pageCount == nil)
        #expect(viewModel.canSave == false)
    }

    // MARK: Saving

    @Test("Saving builds the book out of what was typed")
    func savesTheTypedBook() throws {
        let (viewModel, repository) = makeViewModel()
        viewModel.title = "Sapiens"
        viewModel.author = "Yuval Noah Harari"
        viewModel.genre = .history
        viewModel.pageCountText = "512"
        viewModel.status = .owned

        #expect(viewModel.save())

        let book = try #require(repository.added.first)
        #expect(book.title == "Sapiens")
        #expect(book.author == "Yuval Noah Harari")
        #expect(book.genre == .history)
        #expect(book.pageCount == 512)
        #expect(book.status == .owned)
        #expect(book.currentPage == 0)
    }

    @Test("Surrounding spaces are trimmed off before storing")
    func trimsWhitespace() throws {
        let (viewModel, repository) = makeViewModel()
        viewModel.title = "  Sapiens  "
        viewModel.author = "  Harari "
        viewModel.genre = .history
        viewModel.pageCountText = " 512 "

        #expect(viewModel.save())

        let book = try #require(repository.added.first)
        #expect(book.title == "Sapiens")
        #expect(book.author == "Harari")
        #expect(book.pageCount == 512)
    }

    @Test("An author left blank is stored as absent, not as an empty string")
    func blankAuthorBecomesNil() throws {
        let (viewModel, repository) = makeViewModel()
        viewModel.title = "Sapiens"
        viewModel.author = "   "
        viewModel.genre = .history
        viewModel.pageCountText = "512"

        #expect(viewModel.save())
        #expect(try #require(repository.added.first).author == nil)
    }

    @Test("A new book defaults to the wishlist")
    func defaultsToWishlist() {
        let (viewModel, _) = makeViewModel()
        #expect(viewModel.status == .wishlist)
    }

    @Test("An incomplete form stores nothing")
    func doesNotSaveIncompleteForms() {
        let (viewModel, repository) = makeViewModel()
        viewModel.title = "Sapiens"

        #expect(viewModel.save() == false)
        #expect(repository.added.isEmpty)
    }

    @Test("A failed save reports back instead of pretending it worked")
    func reportsFailedSaves() {
        let (viewModel, repository) = makeViewModel()
        repository.errorToThrow = StubError()
        viewModel.title = "Sapiens"
        viewModel.genre = .history
        viewModel.pageCountText = "512"

        #expect(viewModel.save() == false)
    }
}
