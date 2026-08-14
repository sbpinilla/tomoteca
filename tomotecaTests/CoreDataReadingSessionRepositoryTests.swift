//
//  CoreDataReadingSessionRepositoryTests.swift
//  tomotecaTests
//

import Combine
import CoreData
import Testing
@testable import tomoteca

@MainActor
struct CoreDataReadingSessionRepositoryTests {

    /// A fresh in-memory stack per test, so no test can see another's sessions.
    private func makeStack() -> PersistenceController {
        PersistenceController(inMemory: true)
    }

    private func insert(_ book: Book, into persistence: PersistenceController) throws {
        let context = persistence.container.viewContext
        let entity = BookEntity(context: context)
        entity.id = book.id
        entity.title = book.title
        entity.genreRawValue = book.genre.rawValue
        entity.pageCount = Int32(book.pageCount)
        entity.currentPage = Int32(book.currentPage)
        entity.statusRawValue = book.status.rawValue
        entity.createdAt = book.createdAt
        try context.save()
    }

    /// A session written the way the app wrote them before the starting page existed: everything
    /// else filled in, and `startPage` left empty.
    private func insertLegacySession(
        book: Book,
        daysAgo: Int,
        finalPage: Int,
        startPage: Int? = nil,
        into persistence: PersistenceController
    ) throws {
        let context = persistence.container.viewContext
        let entity = ReadingSessionEntity(context: context)
        entity.id = UUID()
        entity.bookID = book.id
        entity.startedAt = Date(timeIntervalSince1970: 1_700_000_000)
            .addingTimeInterval(TimeInterval(-daysAgo * 86_400))
        entity.endedAt = entity.startedAt!.addingTimeInterval(600)
        entity.plannedMinutes = 10
        entity.actualSeconds = 600
        entity.finalPage = Int32(finalPage)
        entity.startPage = startPage.map(NSNumber.init(value:))
        try context.save()
    }

    private func firstValue(of repository: ReadingSessionRepository) -> [ReadingSession] {
        var received: [ReadingSession] = []
        var cancellables = Set<AnyCancellable>()
        repository.sessions
            .sink { received = $0 }
            .store(in: &cancellables)
        return received
    }

    @Test("A session survives the round trip through the store with both of its pages")
    func storesBothPages() throws {
        let persistence = makeStack()
        try insert(.previewReading, into: persistence)
        let repository = CoreDataReadingSessionRepository(persistence: persistence)

        try repository.add(
            ReadingSession(
                bookID: Book.previewReading.id,
                startedAt: Date(),
                endedAt: Date(),
                plannedMinutes: 15,
                actualSeconds: 900,
                startPage: 210,
                finalPage: 242
            )
        )

        let stored = try #require(firstValue(of: repository).first)
        #expect(stored.startPage == 210)
        #expect(stored.finalPage == 242)
        #expect(stored.pagesRead == 32)
    }

    // MARK: The backfill

    @Test("Sessions recorded before the starting page existed are chained back together")
    func backfillChainsSessionsOfABook() throws {
        let persistence = makeStack()
        try insert(.previewReading, into: persistence)

        // Oldest last, on purpose: the chain has to come from the dates, not the insert order.
        try insertLegacySession(book: .previewReading, daysAgo: 1, finalPage: 130, into: persistence)
        try insertLegacySession(book: .previewReading, daysAgo: 3, finalPage: 40, into: persistence)
        try insertLegacySession(book: .previewReading, daysAgo: 2, finalPage: 92, into: persistence)

        persistence.backfillSessionStartPages()

        let sessions = firstValue(of: CoreDataReadingSessionRepository(persistence: persistence))

        // Newest first, so: 92→130, 40→92, 0→40.
        #expect(sessions.map(\.startPage) == [92, 40, 0])
        #expect(sessions.map(\.pagesRead) == [38, 52, 40])
    }

    @Test("Each book is chained on its own, not through whatever was read in between")
    func backfillKeepsBooksApart() throws {
        let persistence = makeStack()
        let other = Book(title: "Other", genre: .essay, pageCount: 300)
        try insert(.previewReading, into: persistence)
        try insert(other, into: persistence)

        try insertLegacySession(book: .previewReading, daysAgo: 3, finalPage: 40, into: persistence)
        try insertLegacySession(book: other, daysAgo: 2, finalPage: 25, into: persistence)
        try insertLegacySession(book: .previewReading, daysAgo: 1, finalPage: 90, into: persistence)

        persistence.backfillSessionStartPages()

        let sessions = firstValue(of: CoreDataReadingSessionRepository(persistence: persistence))
        let byFinalPage = Dictionary(
            sessions.map { ($0.finalPage, $0.startPage) },
            uniquingKeysWith: { first, _ in first }
        )

        #expect(byFinalPage[40] == 0, "First session of its book")
        #expect(byFinalPage[90] == 40, "Picks up where that same book left off")
        #expect(byFinalPage[25] == 0, "The other book starts from its own beginning")
    }

    @Test("A session that already has a starting page is left alone")
    func backfillLeavesRecordedPagesAlone() throws {
        let persistence = makeStack()
        try insert(.previewReading, into: persistence)

        try insertLegacySession(
            book: .previewReading,
            daysAgo: 1,
            finalPage: 260,
            startPage: 210,
            into: persistence
        )

        persistence.backfillSessionStartPages()

        let stored = try #require(
            firstValue(of: CoreDataReadingSessionRepository(persistence: persistence)).first
        )
        #expect(stored.startPage == 210, "A recorded page is a fact; the chain is only a guess")
    }
}
