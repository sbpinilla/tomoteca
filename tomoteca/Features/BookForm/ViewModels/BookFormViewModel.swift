//
//  BookFormViewModel.swift
//  tomoteca
//

import Combine
import Foundation

/// What the form is for. The same screen serves both, because two parallel forms drift apart
/// the moment a field is added to one of them.
enum BookFormMode {
    case add
    case edit(Book)
}

/// Backs the book form: holds what is typed, decides when it is valid, and saves.
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
    private let mode: BookFormMode

    init(mode: BookFormMode, repository: BookRepository) {
        self.mode = mode
        self.repository = repository

        if case .edit(let book) = mode {
            title = book.title
            author = book.author ?? ""
            genre = book.genre
            pageCountText = String(book.pageCount)
            status = book.status
            coverImageData = book.coverImageData
        }
    }

    /// Editing never offers the status. Advancing is the status sheet's job alone, so that the
    /// one-way rule has no back door through the edit form.
    var showsStatusPicker: Bool {
        if case .add = mode { return true }
        return false
    }

    var navigationTitle: LocalizedStringResource {
        switch mode {
        case .add: return .bookFormNewTitle
        case .edit: return .bookFormEditTitle
        }
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
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanAuthor = trimmedAuthor.isEmpty ? nil : trimmedAuthor

        // No assertion here: a failed write is a real runtime condition — a full disk, a locked
        // store — not a programming mistake, and crashing debug builds over it helps nobody.
        // TODO: surface the failure to the reader once the form can show an error.
        do {
            switch mode {
            case .add:
                try repository.add(
                    Book(
                        title: trimmedTitle,
                        author: cleanAuthor,
                        genre: genre,
                        pageCount: pageCount,
                        status: status,
                        coverImageData: coverImageData
                    )
                )

            case .edit(let original):
                // Rebuilt from the original so everything the form does not show — the id, the
                // creation date, the current page, the status — survives the edit untouched.
                var updated = original
                updated.title = trimmedTitle
                updated.author = cleanAuthor
                updated.genre = genre
                updated.pageCount = pageCount
                updated.coverImageData = coverImageData
                try repository.update(updated)
            }
            return true
        } catch {
            return false
        }
    }
}
