//
//  BookRepository.swift
//  tomoteca
//

import Combine

/// The only door between the app and stored books.
///
/// ViewModels depend on this protocol, never on the Core Data implementation, so the store can
/// be swapped for a remote one — or for a fake in tests — without any of them changing.
protocol BookRepository {

    /// The whole catalog, newest first. Re-emits on every change, and always on the main queue.
    var books: AnyPublisher<[Book], Never> { get }

    /// Stores a new book. `books` re-emits with it included.
    func add(_ book: Book) throws
}
