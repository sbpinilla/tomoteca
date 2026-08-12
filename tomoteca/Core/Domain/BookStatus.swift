//
//  BookStatus.swift
//  tomoteca
//

import Foundation

/// Where a book sits in its life cycle.
///
/// The flow runs in **one direction only**: a book never goes back to a previous status and a
/// finished book is never reopened. The raw values follow that order on purpose, so the stored
/// column sorts the same way the cycle reads.
enum BookStatus: Int16, CaseIterable, Identifiable, Sendable {

    /// Want to buy it.
    case wishlist = 0
    /// Bought, not started.
    case owned = 1
    /// Currently reading.
    case reading = 2
    /// Done.
    case finished = 3

    var id: Int16 { rawValue }

    /// The only status this one can move to, or `nil` once finished.
    ///
    /// The status sheet offers exactly this and nothing else.
    var next: BookStatus? {
        BookStatus(rawValue: rawValue + 1)
    }
}
