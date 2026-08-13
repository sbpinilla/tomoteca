//
//  BookFormViewModelTests.swift
//  tomotecaTests
//

import Foundation
import Testing
@testable import tomoteca

@MainActor
struct BookFormViewModelTests {

    private func makeViewModel(
        mode: BookFormMode = .add
    ) -> (BookFormViewModel, FakeBookRepository) {
        let repository = FakeBookRepository(books: Book.previewCatalog)
        return (BookFormViewModel(mode: mode, repository: repository), repository)
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

        #expect(viewModel.save() != nil)

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

        #expect(viewModel.save() != nil)

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

        #expect(viewModel.save() != nil)
        #expect(try #require(repository.added.first).author == nil)
    }

    @Test("Saving hands back the stored book, so the trunk can follow it to its shelf")
    func savingReturnsTheStoredBook() throws {
        let (viewModel, _) = makeViewModel()
        viewModel.title = "Dune"
        viewModel.genre = .scienceFiction
        viewModel.pageCountText = "412"
        viewModel.status = .owned

        let saved = try #require(viewModel.save())
        #expect(saved.title == "Dune")
        #expect(saved.status == .owned)
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

        #expect(viewModel.save() == nil)
        #expect(repository.added.isEmpty)
    }

    @Test("A failed save reports back instead of pretending it worked")
    func reportsFailedSaves() {
        let (viewModel, repository) = makeViewModel()
        repository.errorToThrow = StubError()
        viewModel.title = "Sapiens"
        viewModel.genre = .history
        viewModel.pageCountText = "512"

        #expect(viewModel.save() == nil)
    }

    // MARK: Editing

    @Test("Editing starts from the book's current values")
    func editingPrefillsTheForm() {
        let (viewModel, _) = makeViewModel(mode: .edit(.previewReading))

        #expect(viewModel.title == Book.previewReading.title)
        #expect(viewModel.author == Book.previewReading.author)
        #expect(viewModel.genre == Book.previewReading.genre)
        #expect(viewModel.pageCountText == "340")
        #expect(viewModel.canSave)
    }

    @Test("Editing does not offer the status, so the one-way rule has no back door")
    func editingHidesTheStatusPicker() {
        let (adding, _) = makeViewModel()
        let (editing, _) = makeViewModel(mode: .edit(.previewReading))

        #expect(adding.showsStatusPicker)
        #expect(editing.showsStatusPicker == false)
    }

    @Test("Saving an edit overwrites the book instead of creating a second one")
    func savingAnEditUpdates() throws {
        let (viewModel, repository) = makeViewModel(mode: .edit(.previewReading))
        viewModel.title = "Cien años de soledad (edición revisada)"

        #expect(viewModel.save() != nil)

        #expect(repository.added.isEmpty)
        let stored = try #require(repository.updated.first)
        #expect(stored.id == Book.previewReading.id)
        #expect(stored.title == "Cien años de soledad (edición revisada)")
    }

    @Test("An edit preserves what the form never shows: status, progress and creation date")
    func editingPreservesHiddenFields() throws {
        let (viewModel, repository) = makeViewModel(mode: .edit(.previewReading))
        viewModel.title = "Otro título"

        #expect(viewModel.save() != nil)

        let stored = try #require(repository.updated.first)
        #expect(stored.status == Book.previewReading.status)
        #expect(stored.currentPage == Book.previewReading.currentPage)
        #expect(stored.createdAt == Book.previewReading.createdAt)
        #expect(stored.coverImageData == Book.previewReading.coverImageData)
    }

    @Test("An edit can change the cover without touching anything else")
    func editingCanReplaceTheCover() throws {
        let (viewModel, repository) = makeViewModel(mode: .edit(.previewReading))
        viewModel.coverImageData = Data([0x09])

        #expect(viewModel.save() != nil)

        let stored = try #require(repository.updated.first)
        #expect(stored.coverImageData == Data([0x09]))
        #expect(stored.title == Book.previewReading.title)
    }
}
