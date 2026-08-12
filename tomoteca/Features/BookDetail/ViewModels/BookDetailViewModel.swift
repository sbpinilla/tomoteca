//
//  BookDetailViewModel.swift
//  tomoteca
//

import Combine
import Foundation

/// Backs the book detail screen and the status advance.
///
/// Subscribes to the catalog rather than holding the book it was handed, so a change made here
/// — or anywhere else — is reflected without the screen being rebuilt.
@MainActor
final class BookDetailViewModel: ObservableObject {

    @Published private(set) var book: Book
    @Published var isChangingStatus = false

    private let repository: BookRepository
    private var cancellables = Set<AnyCancellable>()

    init(book: Book, repository: BookRepository) {
        self.book = book
        self.repository = repository

        repository.books
            .compactMap { $0.first { $0.id == book.id } }
            .assign(to: \.book, on: self)
            .store(in: &cancellables)
    }

    /// The one status this book can move to, or `nil` when it is finished.
    var nextStatus: BookStatus? { book.status.next }

    /// Moves the book one step along the cycle. Does nothing on a finished book.
    func advanceStatus() {
        guard let nextStatus else { return }

        var updated = book
        updated.status = nextStatus

        do {
            try repository.update(updated)
            isChangingStatus = false
        } catch {
            // TODO: surface the failure once the screen can show an error.
        }
    }
}
