//
//  BookListViewModel.swift
//  tomoteca
//

import Combine
import Foundation

/// Drives the trunk list: what is stored, narrowed by the search text and the status filter.
///
/// Knows nothing about Core Data: it receives a `BookRepository` and works off what it emits.
@MainActor
final class BookListViewModel: ObservableObject {

    /// The status filter, with an extra option for "no filter at all".
    enum Filter: Hashable, Identifiable, CaseIterable {
        case all
        case status(BookStatus)

        static var allCases: [Filter] { [.all] + BookStatus.allCases.map(Filter.status) }

        var id: Self { self }

        var title: LocalizedStringResource {
            switch self {
            case .all: return .trunkFilterAll
            case .status(let status): return status.shortTitle
            }
        }
    }

    @Published var searchText = ""
    @Published var filter: Filter = .all

    @Published private(set) var books: [Book] = []

    private let repository: BookRepository
    private var cancellables = Set<AnyCancellable>()

    init(repository: BookRepository) {
        self.repository = repository

        repository.books
            .assign(to: \.books, on: self)
            .store(in: &cancellables)
    }

    /// Removes a book. Swipe-to-delete is deliberate enough on its own, so there is no
    /// confirmation step in front of it.
    func delete(_ book: Book) {
        do {
            try repository.delete(id: book.id)
        } catch {
            // TODO: surface the failure once the screen can show an error.
        }
    }

    /// The book behind a swipe, resolved **within the visible list**, which is not the same as
    /// the stored catalog whenever a search or filter is active.
    func book(atOffsets offsets: IndexSet) -> Book? {
        let visible = visibleBooks
        guard let index = offsets.first, visible.indices.contains(index) else { return nil }
        return visible[index]
    }

    /// What the list actually shows: the catalog after the filter and then the search.
    ///
    /// The two combine rather than override each other — after filtering to "reading", a search
    /// is expected to look inside that shelf, not start over from the whole library.
    var visibleBooks: [Book] {
        books
            .filter(matchesFilter)
            .filter(matchesSearch)
    }

    /// Nothing stored at all, as opposed to nothing matching.
    var isEmpty: Bool { books.isEmpty }

    /// Books exist, but none survives the current search or filter.
    var hasNoResults: Bool { !books.isEmpty && visibleBooks.isEmpty }

    private func matchesFilter(_ book: Book) -> Bool {
        switch filter {
        case .all: return true
        case .status(let status): return book.status == status
        }
    }

    private func matchesSearch(_ book: Book) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }

        // Diacritic- and case-insensitive: "garcia" has to find García Márquez. Requiring the
        // accent would turn the search box into a spelling test.
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]

        if book.title.range(of: query, options: options) != nil { return true }
        if let author = book.author, author.range(of: query, options: options) != nil { return true }
        return false
    }
}
