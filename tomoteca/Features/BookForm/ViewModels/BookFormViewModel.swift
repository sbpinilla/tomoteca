//
//  BookFormViewModel.swift
//  tomoteca
//

import Combine
import Foundation

/// Backs the add-book form: holds what is typed, decides when it is valid, and saves.
@MainActor
final class BookFormViewModel: ObservableObject {

    @Published var title = ""
    @Published var author = ""
    /// Starts unset on purpose: the genre is required, and a preselected one would quietly
    /// misfile every book whose author forgot to change it.
    @Published var genre: Genre?
    @Published var pageCountText = ""
    @Published var status: BookStatus = .wishlist
    /// Optional, and usually added later: a book on the wishlist is rarely at hand to photograph.
    @Published var coverImageData: Data?

    private let repository: BookRepository

    init(repository: BookRepository) {
        self.repository = repository
    }

    /// Pages as a number, or `nil` when what was typed is not a usable page count.
    var pageCount: Int? {
        guard let value = Int(pageCountText.trimmingCharacters(in: .whitespaces)), value > 0 else {
            return nil
        }
        return value
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && genre != nil
            && pageCount != nil
    }

    /// Stores the book. Returns `false` if the form is incomplete or the save failed, so the
    /// caller can keep the sheet open rather than dismissing over a lost book.
    func save() -> Bool {
        guard let genre, let pageCount, canSave else { return false }

        let trimmedAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)

        let book = Book(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            author: trimmedAuthor.isEmpty ? nil : trimmedAuthor,
            genre: genre,
            pageCount: pageCount,
            status: status,
            coverImageData: coverImageData
        )

        // No assertion here: a failed write is a real runtime condition — a full disk, a locked
        // store — not a programming mistake, and crashing debug builds over it helps nobody.
        // TODO: surface the failure to the reader once the form can show an error.
        do {
            try repository.add(book)
            return true
        } catch {
            return false
        }
    }
}
