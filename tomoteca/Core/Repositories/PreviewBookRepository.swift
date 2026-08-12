//
//  PreviewBookRepository.swift
//  tomoteca
//

#if DEBUG
import Combine
import Foundation

/// In-memory `BookRepository` for SwiftUI previews. No Core Data involved, so a preview never
/// depends on a store loading correctly.
final class PreviewBookRepository: BookRepository {

    static var populated: PreviewBookRepository { PreviewBookRepository(books: Book.previewCatalog) }
    static var empty: PreviewBookRepository { PreviewBookRepository(books: []) }

    private let subject: CurrentValueSubject<[Book], Never>

    init(books: [Book]) {
        subject = CurrentValueSubject(books)
    }

    var books: AnyPublisher<[Book], Never> {
        subject.eraseToAnyPublisher()
    }

    func add(_ book: Book) throws {
        subject.send([book] + subject.value)
    }

    func delete(id: UUID) throws {
        subject.send(subject.value.filter { $0.id != id })
    }

    func update(_ book: Book) throws {
        guard let index = subject.value.firstIndex(where: { $0.id == book.id }) else {
            throw RepositoryError.bookNotFound
        }
        var books = subject.value
        books[index] = book
        subject.send(books)
    }
}
#endif
