//
//  BookArchiveViewModelTests.swift
//  tomotecaTests
//

import Foundation
import Testing
@testable import tomoteca

@MainActor
struct BookArchiveViewModelTests {

    /// Writes JSON to a temporary file, standing in for the one the picker hands back.
    private func makeFile(_ json: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).json")
        try Data(json.utf8).write(to: url)
        return url
    }

    // MARK: Export

    @Test("Exporting writes a file that can be read back")
    func exportWritesAReadableFile() throws {
        let viewModel = BookArchiveViewModel(repository: FakeBookRepository(books: Book.previewCatalog))

        viewModel.export()

        let file = try #require(viewModel.exportedFile)
        let result = try BookArchive.decode(try Data(contentsOf: file.url))
        #expect(result.importedCount == Book.previewCatalog.count)
        #expect(file.url.pathExtension == "json")
    }

    @Test("The screen knows how many books the file will hold")
    func reportsTheBookCount() {
        let viewModel = BookArchiveViewModel(repository: FakeBookRepository(books: Book.previewCatalog))

        #expect(viewModel.bookCount == Book.previewCatalog.count)
    }

    // MARK: Import

    @Test("Importing stores the books it read")
    func importStoresTheBooks() throws {
        let repository = FakeBookRepository()
        let viewModel = BookArchiveViewModel(repository: repository)

        viewModel.import(from: try makeFile("""
        { "version": 1, "books": [
            { "title": "Dune", "genre": "science_fiction", "pageCount": 412 },
            { "title": "Sapiens", "genre": "history", "pageCount": 512 }
        ] }
        """))

        #expect(repository.added.map(\.title) == ["Dune", "Sapiens"])
        #expect(viewModel.lastImport?.importedCount == 2)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Importing adds to the library instead of replacing it")
    func importAddsToWhatIsThere() throws {
        let repository = FakeBookRepository(books: [.previewOwned])
        let viewModel = BookArchiveViewModel(repository: repository)

        viewModel.import(from: try makeFile("""
        { "version": 1, "books": [
            { "title": "Dune", "genre": "science_fiction", "pageCount": 412 }
        ] }
        """))

        #expect(viewModel.books.count == 2)
        #expect(viewModel.books.contains { $0.title == Book.previewOwned.title })
    }

    @Test("A book already in the library is not stored twice")
    func importSkipsBooksAlreadyThere() throws {
        let repository = FakeBookRepository(books: [.previewOwned])
        let viewModel = BookArchiveViewModel(repository: repository)
        let exported = try BookArchive.encode([.previewOwned])
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).json")
        try exported.write(to: url)

        viewModel.import(from: url)

        #expect(repository.added.isEmpty)
        #expect(viewModel.lastImport?.skipped[.alreadyPresent] == 1)
    }

    @Test("The books that are fine go in even when others are not")
    func importKeepsTheGoodBooks() throws {
        let repository = FakeBookRepository()
        let viewModel = BookArchiveViewModel(repository: repository)

        viewModel.import(from: try makeFile("""
        { "version": 1, "books": [
            { "title": "Dune", "genre": "science_fiction", "pageCount": 412 },
            { "title": "Roto", "genre": "no_existe", "pageCount": 100 },
            { "title": "Sin páginas", "genre": "novel" }
        ] }
        """))

        #expect(repository.added.map(\.title) == ["Dune"])
        #expect(viewModel.lastImport?.importedCount == 1)
        #expect(viewModel.lastImport?.skippedCount == 2)
        #expect(viewModel.lastImport?.skipped[.unknownGenre] == 1)
        #expect(viewModel.lastImport?.skipped[.missingFields] == 1)
    }

    // MARK: Files that cannot be read

    @Test("A file that is not a library reports an error and stores nothing")
    func reportsUnreadableFiles() throws {
        let repository = FakeBookRepository()
        let viewModel = BookArchiveViewModel(repository: repository)

        viewModel.import(from: try makeFile("esto no es json"))

        #expect(repository.added.isEmpty)
        #expect(viewModel.lastImport == nil)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("A file from a newer version reports its own error")
    func reportsUnsupportedVersions() throws {
        let viewModel = BookArchiveViewModel(repository: FakeBookRepository())

        viewModel.import(from: try makeFile(#"{ "version": 99, "books": [] }"#))

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.lastImport == nil)
    }

    @Test("A new import clears the error left by the previous one")
    func aGoodImportClearsThePreviousError() throws {
        let viewModel = BookArchiveViewModel(repository: FakeBookRepository())

        viewModel.import(from: try makeFile("roto"))
        #expect(viewModel.errorMessage != nil)

        viewModel.import(from: try makeFile("""
        { "version": 1, "books": [
            { "title": "Dune", "genre": "science_fiction", "pageCount": 412 }
        ] }
        """))

        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.lastImport?.importedCount == 1)
    }
}
