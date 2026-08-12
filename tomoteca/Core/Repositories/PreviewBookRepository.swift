//
//  PreviewBookRepository.swift
//  tomoteca
//

#if DEBUG
import Combine

/// In-memory `BookRepository` for SwiftUI previews. No Core Data involved, so a preview never
/// depends on a store loading correctly.
struct PreviewBookRepository: BookRepository {

    static let populated = PreviewBookRepository(books: Book.previewCatalog)
    static let empty = PreviewBookRepository(books: [])

    private let value: [Book]

    init(books: [Book]) {
        self.value = books
    }

    var books: AnyPublisher<[Book], Never> {
        Just(value).eraseToAnyPublisher()
    }
}
#endif
