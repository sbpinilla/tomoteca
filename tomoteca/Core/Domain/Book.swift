//
//  Book.swift
//  tomoteca
//

import Foundation

/// A book in the personal library.
///
/// This is the type the rest of the app works with. `NSManagedObject` never leaves the
/// repository, so nothing above it depends on Core Data.
struct Book: Identifiable, Equatable, Hashable, Sendable {

    let id: UUID
    var title: String
    /// Optional, but part of the search index when present.
    var author: String?
    var genre: Genre
    /// Required: without it there is no progress to show.
    var pageCount: Int
    var currentPage: Int
    var status: BookStatus
    var coverImageData: Data?
    var createdAt: Date
    /// When the book arrived at its current status.
    ///
    /// Set on creation and rewritten on every move, so that the shelf a book just landed on
    /// shows it first. Without it, a book bought today would sit wherever its registration date
    /// happened to put it.
    var statusChangedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        author: String? = nil,
        genre: Genre,
        pageCount: Int,
        currentPage: Int = 0,
        status: BookStatus = .wishlist,
        coverImageData: Data? = nil,
        createdAt: Date = Date(),
        statusChangedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.genre = genre
        self.pageCount = pageCount
        self.currentPage = currentPage
        self.status = status
        self.coverImageData = coverImageData
        self.createdAt = createdAt
        // A book that has never moved counts as having arrived when it was registered.
        self.statusChangedAt = statusChangedAt ?? createdAt
    }

    /// How far through the book the reader is, from 0 to 1.
    ///
    /// Clamped on both ends: a page count that drifts out of range — an edited book, a typo in
    /// the final page of a session — must never produce a negative bar or one past the end.
    var progress: Double {
        guard pageCount > 0 else { return 0 }
        return min(1, max(0, Double(currentPage) / Double(pageCount)))
    }
}
