//
//  FakeBookRepository.swift
//  tomotecaTests
//

import Combine
@testable import tomoteca

/// The single `BookRepository` double for the whole test target.
///
/// One fake instead of one per test file: every method the protocol gains only has to be
/// implemented here, and a change to the protocol breaks one type rather than four.
///
/// Holds a mutable catalog, so a ViewModel writing through it sees its own change come back.
final class FakeBookRepository: BookRepository {

    /// Set to make the next write fail, for testing what happens when the store refuses.
    var errorToThrow: (any Error)?

    private(set) var added: [Book] = []
    private(set) var updateCount = 0

    private let subject: CurrentValueSubject<[Book], Never>

    init(books: [Book] = []) {
        subject = CurrentValueSubject(books)
    }

    var books: AnyPublisher<[Book], Never> {
        subject.eraseToAnyPublisher()
    }

    func add(_ book: Book) throws {
        if let errorToThrow { throw errorToThrow }
        added.append(book)
        subject.send([book] + subject.value)
    }

    func update(_ book: Book) throws {
        if let errorToThrow { throw errorToThrow }
        guard let index = subject.value.firstIndex(where: { $0.id == book.id }) else {
            throw RepositoryError.bookNotFound
        }
        updateCount += 1
        var books = subject.value
        books[index] = book
        subject.send(books)
    }

    /// Replaces the catalog outright, standing in for a change made somewhere else.
    func emit(_ books: [Book]) {
        subject.send(books)
    }
}

/// Failure with no meaning of its own, for tests that only care that something went wrong.
struct StubError: Error {}
