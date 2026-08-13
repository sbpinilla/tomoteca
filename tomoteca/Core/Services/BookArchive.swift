//
//  BookArchive.swift
//  tomoteca
//

import Foundation

/// The JSON exchange format for a library.
///
/// Written to be edited by hand: statuses and genres travel as words rather than as the numbers
/// the store uses, so a file can be typed out without knowing anything about the app's insides —
/// and so that changing those insides does not invalidate files already written.
enum BookArchive {

    /// Bumped when the shape of the file changes. A file from the future is refused rather than
    /// read halfway.
    static let currentVersion = 1

    // MARK: The file

    struct File: Codable {
        let version: Int
        var exportedAt: Date?
        let books: [Entry]
    }

    /// One book as it appears in the file. Everything optional but the three fields a book
    /// cannot exist without, so a hand-written entry can be a single line.
    struct Entry: Codable {
        let id: UUID?
        let title: String?
        let author: String?
        let genre: String?
        let pageCount: Int?
        let currentPage: Int?
        let status: String?
        let createdAt: Date?
    }

    // MARK: Results

    /// Why a book in the file did not make it into the library.
    enum SkipReason: String, CaseIterable, Hashable {
        case missingFields
        case unknownGenre
        case unknownStatus
        case invalidNumbers
        case alreadyPresent
    }

    /// What an import produced: the books ready to store, and a tally of what was left out.
    struct ImportResult: Equatable {
        var books: [Book] = []
        var skipped: [SkipReason: Int] = [:]

        var importedCount: Int { books.count }
        var skippedCount: Int { skipped.values.reduce(0, +) }

        mutating func skip(_ reason: SkipReason) {
            skipped[reason, default: 0] += 1
        }
    }

    /// What can go wrong with the file as a whole, as opposed to with one book inside it.
    enum ArchiveError: Error, Equatable {
        /// Not JSON, or JSON that is not a library.
        case unreadable
        /// Written by a version of the app that knows something this one does not.
        case unsupportedVersion(Int)
    }

    // MARK: Writing

    static func encode(_ books: [Book], exportedAt: Date = Date()) throws -> Data {
        let file = File(
            version: currentVersion,
            exportedAt: exportedAt,
            books: books.map(Entry.init(from:))
        )

        let encoder = JSONEncoder()
        // Readable on purpose: the file is meant to be opened and edited, not just moved around.
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601

        return try encoder.encode(file)
    }

    // MARK: Reading

    /// Turns a file into books, skipping the entries it cannot use.
    ///
    /// A broken book never stops the import: it is counted and the rest carries on. A file that
    /// somebody typed out will have mistakes, and losing forty good books to one stray comma
    /// would be a poor trade.
    static func decode(
        _ data: Data,
        existingIDs: Set<UUID> = [],
        now: Date = Date()
    ) throws -> ImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let file = try? decoder.decode(LenientFile.self, from: data) else {
            throw ArchiveError.unreadable
        }

        guard file.version <= currentVersion else {
            throw ArchiveError.unsupportedVersion(file.version)
        }

        var result = ImportResult()
        var seen = existingIDs

        for entry in file.books {
            // A single entry with the wrong type somewhere — a page count written as text —
            // decodes to nothing rather than taking the whole array down with it.
            guard let entry = entry.value else {
                result.skip(.missingFields)
                continue
            }

            switch makeBook(from: entry, existingIDs: seen, now: now) {
            case .book(let book):
                seen.insert(book.id)
                result.books.append(book)
            case .skipped(let reason):
                result.skip(reason)
            }
        }

        return result
    }

    /// What one entry turned into. Not a `Result`, because a skipped book is an ordinary
    /// outcome of reading a hand-written file, not an error.
    private enum Outcome {
        case book(Book)
        case skipped(SkipReason)
    }

    private static func makeBook(
        from entry: Entry,
        existingIDs: Set<UUID>,
        now: Date
    ) -> Outcome {
        guard
            let title = entry.title?.trimmingCharacters(in: .whitespacesAndNewlines),
            !title.isEmpty,
            let rawGenre = entry.genre,
            let pageCount = entry.pageCount
        else {
            return .skipped(.missingFields)
        }

        guard let genre = Genre(rawValue: rawGenre) else {
            return .skipped(.unknownGenre)
        }

        // Absent means wishlist; present but unrecognised is a mistake worth reporting, not a
        // value to guess at.
        let status: BookStatus
        if let rawStatus = entry.status {
            guard let parsed = BookStatus(archiveName: rawStatus) else {
                return .skipped(.unknownStatus)
            }
            status = parsed
        } else {
            status = .wishlist
        }

        let currentPage = entry.currentPage ?? 0
        guard pageCount > 0, currentPage >= 0, currentPage <= pageCount else {
            return .skipped(.invalidNumbers)
        }

        let id = entry.id ?? UUID()
        guard !existingIDs.contains(id) else {
            return .skipped(.alreadyPresent)
        }

        let author = entry.author?.trimmingCharacters(in: .whitespacesAndNewlines)

        return .book(
            Book(
                id: id,
                title: title,
                author: (author?.isEmpty ?? true) ? nil : author,
                genre: genre,
                pageCount: pageCount,
                currentPage: currentPage,
                status: status,
                // Covers stay out of the format: in base64 they would bloat the file past the
                // point of being editable, which is what makes it useful.
                coverImageData: nil,
                createdAt: entry.createdAt ?? now
            )
        )
    }

    // MARK: Lenient decoding

    /// The file, with its books decoded one by one so a bad entry cannot sink the good ones.
    private struct LenientFile: Decodable {
        let version: Int
        let books: [Lenient<Entry>]
    }

    /// Decodes to `nil` instead of throwing, which is what keeps one malformed entry local.
    private struct Lenient<Wrapped: Decodable>: Decodable {
        let value: Wrapped?

        init(from decoder: Decoder) throws {
            value = try? Wrapped(from: decoder)
        }
    }
}

// MARK: - Mapping to and from the domain

private extension BookArchive.Entry {

    init(from book: Book) {
        id = book.id
        title = book.title
        author = book.author
        genre = book.genre.rawValue
        pageCount = book.pageCount
        currentPage = book.currentPage
        status = book.status.archiveName
        createdAt = book.createdAt
    }
}

extension BookStatus {

    /// The status as it appears in an exported file.
    ///
    /// Deliberately not the stored `rawValue`: `1` says nothing to someone writing the file by
    /// hand, and it would tie the format to a storage detail that is free to change.
    var archiveName: String {
        switch self {
        case .wishlist: return "wishlist"
        case .owned: return "owned"
        case .reading: return "reading"
        case .finished: return "finished"
        }
    }

    init?(archiveName: String) {
        guard let match = BookStatus.allCases.first(where: { $0.archiveName == archiveName }) else {
            return nil
        }
        self = match
    }
}
