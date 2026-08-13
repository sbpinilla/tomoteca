//
//  BookArchiveViewModel.swift
//  tomoteca
//

import Combine
import Foundation

/// Backs the import and export screen.
@MainActor
final class BookArchiveViewModel: ObservableObject {

    @Published private(set) var books: [Book] = []
    /// The result of the last import, kept on screen until the reader leaves.
    @Published private(set) var lastImport: BookArchive.ImportResult?
    @Published private(set) var errorMessage: LocalizedStringResource?
    /// The generated file, ready to hand to the share sheet.
    @Published var exportedFile: ExportedFile?

    private let repository: BookRepository
    private var cancellables = Set<AnyCancellable>()

    init(repository: BookRepository) {
        self.repository = repository

        repository.books
            .assign(to: \.books, on: self)
            .store(in: &cancellables)
    }

    var bookCount: Int { books.count }

    // MARK: Export

    /// Writes the library to a file in the temporary directory and hands back its location.
    ///
    /// A file rather than raw data: the share sheet shows a name and an extension, and what
    /// arrives on the other side is something that can be opened and edited.
    func export() {
        errorMessage = nil

        do {
            let data = try BookArchive.encode(books)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(Self.fileName())

            try data.write(to: url, options: .atomic)
            exportedFile = ExportedFile(url: url)
        } catch {
            errorMessage = .archiveErrorUnreadable
        }
    }

    private static func fileName() -> String {
        let day = Date().formatted(.iso8601.year().month().day().dateSeparator(.dash))
        return "tomoteca-\(day).json"
    }

    // MARK: Import

    func `import`(from url: URL) {
        errorMessage = nil
        lastImport = nil

        // The picker hands back a file outside the app's own container; without asking, reading
        // it is refused.
        let needsRelease = url.startAccessingSecurityScopedResource()
        defer { if needsRelease { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            let result = try BookArchive.decode(data, existingIDs: Set(books.map(\.id)))

            for book in result.books {
                try repository.add(book)
            }

            lastImport = result
        } catch BookArchive.ArchiveError.unsupportedVersion {
            errorMessage = .archiveErrorVersion
        } catch {
            errorMessage = .archiveErrorUnreadable
        }
    }

    func importFailed() {
        errorMessage = .archiveErrorUnreadable
    }
}

/// A file on its way to the share sheet. Wrapped because a `URL` cannot drive `sheet(item:)`
/// on its own.
struct ExportedFile: Identifiable {
    let url: URL
    var id: String { url.path }
}
