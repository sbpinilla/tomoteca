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

    /// Screen titles: "Baúl", "Seguimiento".
    static let title = Font.system(.title2, design: .rounded, weight: .bold)

    /// Item titles: a book title in a list row, a card heading.
    static let headline = Font.system(.subheadline, design: .rounded, weight: .semibold)

    /// Default body copy and control labels.
    static let body = Font.system(.body, design: .rounded, weight: .regular)

    /// Secondary copy: a supporting line under a title.
    static let callout = Font.system(.callout, design: .rounded, weight: .regular)

    /// Metadata: author, genre, page counts, chart labels. Usually in `textSecondary`.
    static let footnote = Font.system(.footnote, design: .rounded, weight: .regular)

    /// Smallest role: section headers, timestamps.
    static let caption = Font.system(.caption, design: .rounded, weight: .medium)
}
