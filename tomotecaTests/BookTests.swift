//
//  BookTests.swift
//  tomotecaTests
//

import Testing
@testable import tomoteca

struct BookTests {

    @Test("Progress is the read fraction of the book")
    func progressIsReadFraction() {
        let book = Book(title: "A", genre: .novel, pageCount: 200, currentPage: 50)
        #expect(book.progress == 0.25)
    }

    @Test("A book with no pages read has no progress")
    func progressStartsAtZero() {
        let book = Book(title: "A", genre: .novel, pageCount: 200)
        #expect(book.progress == 0)
    }

    @Test("Progress never exceeds the end of the book")
    func progressIsClampedAtTheEnd() {
        // Happens after editing a book down to fewer pages than already read.
        let book = Book(title: "A", genre: .novel, pageCount: 100, currentPage: 150)
        #expect(book.progress == 1)
    }

    @Test("A book without pages reports no progress instead of dividing by zero")
    func progressWithoutPagesIsZero() {
        let book = Book(title: "A", genre: .novel, pageCount: 0, currentPage: 10)
        #expect(book.progress == 0)
    }

    @Test("Status advances one step at a time and stops at finished")
    func statusMovesForwardOnly() {
        #expect(BookStatus.wishlist.next == .owned)
        #expect(BookStatus.owned.next == .reading)
        #expect(BookStatus.reading.next == .finished)
        #expect(BookStatus.finished.next == nil)
    }

    @Test("Every genre belongs to exactly one picker section")
    func everyGenreIsFiledOnce() {
        let sectioned = Genre.Section.allCases.flatMap(\.genres)
        #expect(sectioned.count == Genre.allCases.count)
        #expect(Set(sectioned) == Set(Genre.allCases))
    }
}
