//
//  BookStatusStyle.swift
//  tomoteca
//

import SwiftUI

/// Turns a `BookStatus` into what the screen needs to draw it.
///
/// This mapping lives between the two halves on purpose: the design system must not know what a
/// book is, and the domain must not import SwiftUI. It sits in `Features/Shared` because more
/// than one feature draws a status — the trunk list, the detail screen and the in-progress tab.
extension BookStatus {

    var title: LocalizedStringResource {
        switch self {
        case .wishlist: return .statusWishlist
        case .owned: return .statusOwned
        case .reading: return .statusReading
        case .finished: return .statusFinished
        }
    }

    var color: Color {
        switch self {
        case .wishlist: return AppColor.Status.wishlist
        case .owned: return AppColor.Status.owned
        case .reading: return AppColor.Status.reading
        case .finished: return AppColor.Status.finished
        }
    }
}
