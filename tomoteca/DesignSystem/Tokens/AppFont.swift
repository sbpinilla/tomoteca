//
//  AppFont.swift
//  tomoteca
//

import SwiftUI

/// Typography tokens, named by **role** rather than by size.
///
/// The app uses SF Pro Rounded throughout. It is a system face, reached through
/// `design: .rounded` — there is nothing to bundle and no custom font file.
///
/// Every token is built on a system text style, so Dynamic Type keeps working:
/// the sizes below scale with the user's setting. Never call `.font(.system(size:))`
/// outside this file — a fixed point size does not scale and breaks accessibility.
enum AppFont {

    /// Screen-level titles, one per screen at most.
    static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)

    /// Section titles inside a screen.
    static let title = Font.system(.title, design: .rounded, weight: .semibold)

    /// Emphasized item titles: a book title in a row, a card heading.
    static let headline = Font.system(.headline, design: .rounded, weight: .semibold)

    /// Default body copy.
    static let body = Font.system(.body, design: .rounded, weight: .regular)

    /// Secondary copy: an author under a title, a supporting line.
    static let callout = Font.system(.callout, design: .rounded, weight: .regular)

    /// Smallest role: metadata, chip labels, timestamps.
    static let caption = Font.system(.caption, design: .rounded, weight: .medium)
}
