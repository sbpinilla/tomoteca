//
//  BookArchiveTests.swift
//  tomotecaTests
//

import Foundation
import Testing
@testable import tomoteca

struct BookArchiveTests {

    /// Builds a file from raw JSON, the way a hand-written one arrives.
    private func data(_ json: String) -> Data {
        Data(json.utf8)
    }

    // MARK: Round trip

    @Test("A library survives being exported and imported again")
    func roundTripKeepsTheBooks() throws {
        let exported = try BookArchive.encode(Book.previewCatalog)

        let result = try BookArchive.decode(exported)

        #expect(result.importedCount == Book.previewCatalog.count)
        #expect(result.skippedCount == 0)
        #expect(result.books.map(\.title) == Book.previewCatalog.map(\.title))
        #expect(result.books.map(\.genre) == Book.previewCatalog.map(\.genre))
        #expect(result.books.map(\.status) == Book.previewCatalog.map(\.status))
        #expect(result.books.map(\.pageCount) == Book.previewCatalog.map(\.pageCount))
        #expect(result.books.map(\.currentPage) == Book.previewCatalog.map(\.currentPage))
    }

    @Test("Identity and dates survive the round trip, so reimporting is recognised as the same book")
    func roundTripKeepsIdentity() throws {
        let exported = try BookArchive.encode([.previewReading])

        let book = try #require(try BookArchive.decode(exported).books.first)

        #expect(book.id == Book.previewReading.id)
        #expect(book.createdAt == Book.previewReading.createdAt)
        #expect(book.author == Book.previewReading.author)
    }

    @Test("Covers do not travel in the file")
    func roundTripDropsCovers() throws {
        #expect(Book.previewReading.coverImageData != nil, "The sample needs a cover to test this")

        let exported = try BookArchive.encode([.previewReading])
        let book = try #require(try BookArchive.decode(exported).books.first)

        #expect(book.coverImageData == nil)
    }

    @Test("Statuses and genres are written as words, not as stored numbers")
    func exportsReadableValues() throws {
        let exported = try BookArchive.encode([.previewOwned])
        let json = try #require(String(data: exported, encoding: .utf8))

        #expect(json.contains("\"owned\""))
        #expect(json.contains("\"history\""))
        #expect(json.contains("\"status\" : 1") == false)
    }

    // MARK: Hand-written files

    @Test("A file with only the required fields works")
    func acceptsTheMinimumFile() throws {
        let result = try BookArchive.decode(data("""
        { "version": 1, "books": [
            { "title": "Dune", "genre": "science_fiction", "pageCount": 412 }
        ] }
        """))

        let book = try #require(result.books.first)
        #expect(book.title == "Dune")
        #expect(book.author == nil)
        #expect(book.currentPage == 0)
        #expect(book.status == .wishlist, "A book with no status is one you want to buy")
    }

    @Test("An empty library is a valid file")
    func acceptsAnEmptyLibrary() throws {
        let result = try BookArchive.decode(data(#"{ "version": 1, "books": [] }"#))

        #expect(result.importedCount == 0)
        #expect(result.skippedCount == 0)
    }

    @Test("Surrounding spaces are trimmed, and an author of only spaces is no author")
    func trimsWhatWasTyped() throws {
        let result = try BookArchive.decode(data("""
        { "version": 1, "books": [
            { "title": "  Dune  ", "author": "   ", "genre": "science_fiction", "pageCount": 412 }
        ] }
        """))

        let book = try #require(result.books.first)
        #expect(book.title == "Dune")
        #expect(book.author == nil)
    }

    // MARK: One bad book does not sink the file

    @Test("A field of the wrong type skips its own book and no other")
    func aWrongTypeStaysLocal() throws {
        // The page count is text. Decoding the array as a whole would throw here and lose the
        // two good books with it.
        let result = try BookArchive.decode(data("""
        { "version": 1, "books": [
            { "title": "Dune", "genre": "science_fiction", "pageCount": 412 },
            { "title": "Roto", "genre": "novel", "pageCount": "muchas" },
            { "title": "Sapiens", "genre": "history", "pageCount": 512 }
        ] }
        """))

        #expect(result.books.map(\.title) == ["Dune", "Sapiens"])
        #expect(result.skippedCount == 1)
    }

    @Test("A book missing a required field is skipped", arguments: [
        #"{ "genre": "novel", "pageCount": 100 }"#,
        #"{ "title": "Sin género", "pageCount": 100 }"#,
        #"{ "title": "Sin páginas", "genre": "novel" }"#,
        #"{ "title": "   ", "genre": "novel", "pageCount": 100 }"#,
    ])
    func skipsBooksMissingRequiredFields(_ entry: String) throws {
        let result = try BookArchive.decode(data(#"{ "version": 1, "books": [\#(entry)] }"#))

        #expect(result.importedCount == 0)
        #expect(result.skipped[.missingFields] == 1)
    }

    @Test("A genre the app does not know is skipped as such")
    func skipsUnknownGenres() throws {
        // The display name instead of the identifier: the likeliest mistake by far.
        let result = try BookArchive.decode(data("""
        { "version": 1, "books": [
            { "title": "Dune", "genre": "Ciencia ficción", "pageCount": 412 }
        ] }
        """))

        #expect(result.skipped[.unknownGenre] == 1)
    }

    @Test("A status the app does not know is skipped rather than guessed at")
    func skipsUnknownStatuses() throws {
        let result = try BookArchive.decode(data("""
        { "version": 1, "books": [
            { "title": "Dune", "genre": "science_fiction", "pageCount": 412, "status": "leyendo" }
        ] }
        """))

        #expect(result.skipped[.unknownStatus] == 1)
    }

    @Test("Impossible page numbers are skipped", arguments: [
        #"{ "title": "A", "genre": "novel", "pageCount": 0 }"#,
        #"{ "title": "A", "genre": "novel", "pageCount": -10 }"#,
        #"{ "title": "A", "genre": "novel", "pageCount": 300, "currentPage": 350 }"#,
        #"{ "title": "A", "genre": "novel", "pageCount": 300, "currentPage": -1 }"#,
    ])
    func skipsImpossiblePageNumbers(_ entry: String) throws {
        let result = try BookArchive.decode(data(#"{ "version": 1, "books": [\#(entry)] }"#))

        #expect(result.importedCount == 0)
        #expect(result.skipped[.invalidNumbers] == 1)
    }

    @Test("Reimporting the same file adds nothing the second time")
    func skipsBooksAlreadyInTheLibrary() throws {
        let exported = try BookArchive.encode(Book.previewCatalog)

        let result = try BookArchive.decode(exported, existingIDs: Set(Book.previewCatalog.map(\.id)))

        #expect(result.importedCount == 0)
        #expect(result.skipped[.alreadyPresent] == Book.previewCatalog.count)
    }

    @Test("A file repeating the same id twice only brings the book in once")
    func skipsDuplicatesWithinTheSameFile() throws {
        let id = UUID().uuidString
        let result = try BookArchive.decode(data("""
        { "version": 1, "books": [
            { "id": "\(id)", "title": "Dune", "genre": "science_fiction", "pageCount": 412 },
            { "id": "\(id)", "title": "Dune otra vez", "genre": "science_fiction", "pageCount": 412 }
        ] }
        """))

        #expect(result.importedCount == 1)
        #expect(result.skipped[.alreadyPresent] == 1)
    }

    @Test("Two books without ids are both kept: there is nothing to tell them apart by")
    func keepsBooksWithoutIDs() throws {
        let result = try BookArchive.decode(data("""
        { "version": 1, "books": [
            { "title": "Dune", "genre": "science_fiction", "pageCount": 412 },
            { "title": "Dune", "genre": "science_fiction", "pageCount": 412 }
        ] }
        """))

        #expect(result.importedCount == 2)
    }

    // MARK: Files that cannot be read at all

    @Test("Something that is not a library is refused", arguments: [
        "no soy json",
        "{}",
        #"{ "books": [] }"#,
        #"[{ "title": "Dune" }]"#,
        "",
    ])
    func refusesFilesThatAreNotLibraries(_ json: String) {
        #expect(throws: BookArchive.ArchiveError.unreadable) {
            try BookArchive.decode(data(json))
        }
    }

    @Test("A file from a newer version is refused instead of read halfway")
    func refusesNewerVersions() {
        #expect(throws: BookArchive.ArchiveError.unsupportedVersion(99)) {
            try BookArchive.decode(data(#"{ "version": 99, "books": [] }"#))
        }
    }
}
