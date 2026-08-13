//
//  BookListViewModel.swift
//  tomoteca
//

import Combine
import Foundation

/// Drives the trunk: one shelf at a time, narrowed by the search text.
///
/// Knows nothing about Core Data: it receives a `BookRepository` and works off what it emits.
@MainActor
final class BookListViewModel: ObservableObject {

    /// Where the shelf choice is remembered between launches.
    static let selectedShelfKey = "trunkSelectedShelf"

    /// Opens on the bought shelf, which is where most of a library sits.
    private static let defaultShelf = BookStatus.owned

    @Published var searchText = ""
    @Published var shelf: BookStatus {
        didSet { defaults.set(Int(shelf.rawValue), forKey: Self.selectedShelfKey) }
    }

    @Published private(set) var books: [Book] = []

    private let repository: BookRepository
    private let defaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()

    init(repository: BookRepository, defaults: UserDefaults = .standard) {
        self.repository = repository
        self.defaults = defaults
        self.shelf = Self.storedShelf(in: defaults)

        repository.books
            .assign(to: \.books, on: self)
            .store(in: &cancellables)
    }

    private static func storedShelf(in defaults: UserDefaults) -> BookStatus {
        guard
            defaults.object(forKey: selectedShelfKey) != nil,
            let stored = BookStatus(rawValue: Int16(defaults.integer(forKey: selectedShelfKey)))
        else {
            return defaultShelf
        }
        return stored
    }

    /// The shelves, in the order the life cycle runs.
    var shelves: [BookStatus] { BookStatus.allCases }

    /// What the list shows: the chosen shelf, narrowed by the search, newest arrival first.
    ///
    /// Sorted by when each book **reached this shelf**, not by when it was registered. A book
    /// bought today belongs at the top even if it was added to the wishlist months ago.
    var visibleBooks: [Book] {
        books
            .filter { $0.status == shelf }
            .filter(matchesSearch)
            .sorted { $0.statusChangedAt > $1.statusChangedAt }
    }

    /// How many books sit on a shelf, for its chip. Ignores the search: the count answers
    /// "is there anything over there", which a search would keep changing underneath.
    func count(of status: BookStatus) -> Int {
        books.filter { $0.status == status }.count
    }

    /// Nothing stored at all, as opposed to nothing on this shelf.
    var isEmpty: Bool { books.isEmpty }

    /// The shelf is empty, and no search is hiding anything.
    var isShelfEmpty: Bool {
        !books.isEmpty && count(of: shelf) == 0
    }

    /// The shelf has books, but none survives the current search.
    var hasNoResults: Bool {
        count(of: shelf) > 0 && visibleBooks.isEmpty
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
    /// the stored catalog whenever a shelf or a search is narrowing it.
    func book(atOffsets offsets: IndexSet) -> Book? {
        let visible = visibleBooks
        guard let index = offsets.first, visible.indices.contains(index) else { return nil }
        return visible[index]
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
