//
//  BookListViewModel.swift
//  tomoteca
//

import Combine
import Foundation

/// Drives the trunk list.
///
/// Knows nothing about Core Data: it receives a `BookRepository` and republishes what it emits.
@MainActor
final class BookListViewModel: ObservableObject {

    @Published private(set) var books: [Book] = []

    private var cancellables = Set<AnyCancellable>()

    init(repository: BookRepository) {
        repository.books
            .assign(to: \.books, on: self)
            .store(in: &cancellables)
    }

    var isEmpty: Bool { books.isEmpty }
}
