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
}
