//
//  InProgressViewModel.swift
//  tomoteca
//

import Combine
import Foundation

/// The books currently being read. A curated view, with no search or filters of its own.
@MainActor
final class InProgressViewModel: ObservableObject {

    @Published private(set) var books: [Book] = []

    private var cancellables = Set<AnyCancellable>()

    init(repository: BookRepository) {
        repository.books
            .map { $0.filter { $0.status == .reading } }
            .assign(to: \.books, on: self)
            .store(in: &cancellables)
    }

    var isEmpty: Bool { books.isEmpty }

    /// The one book being read, when there is exactly one.
    ///
    /// With a single book there is nothing to choose, so the tab can offer the session itself.
    /// With two the choice is real, and making it is what entering the book is for.
    var onlyBook: Book? {
        books.count == 1 ? books.first : nil
    }
}
