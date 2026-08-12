//
//  Book+Samples.swift
//  tomoteca
//

#if DEBUG
import Foundation

/// Sample books for previews, tests and the seeded simulator run. Debug-only: never shipped.
extension Book {

    static let previewReading = Book(
        title: "Cien años de soledad",
        author: "Gabriel García Márquez",
        genre: .novel,
        pageCount: 340,
        currentPage: 210,
        status: .reading,
        createdAt: Date(timeIntervalSince1970: 1_700_000_000)
    )

    static let previewOwned = Book(
        title: "Sapiens",
        author: "Yuval Noah Harari",
        genre: .history,
        pageCount: 512,
        status: .owned,
        createdAt: Date(timeIntervalSince1970: 1_699_000_000)
    )

    static let previewWishlist = Book(
        title: "Project Hail Mary",
        author: "Andy Weir",
        genre: .scienceFiction,
        pageCount: 496,
        status: .wishlist,
        createdAt: Date(timeIntervalSince1970: 1_698_000_000)
    )

    static let previewFinished = Book(
        title: "El nombre de la rosa",
        author: "Umberto Eco",
        genre: .historicalFiction,
        pageCount: 624,
        currentPage: 624,
        status: .finished,
        createdAt: Date(timeIntervalSince1970: 1_697_000_000)
    )

    /// Newest first, the same order the repository returns.
    static let previewCatalog: [Book] = [
        .previewReading, .previewOwned, .previewWishlist, .previewFinished,
    ]
}
#endif
