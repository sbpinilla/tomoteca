//
//  AppColor.swift
//  tomoteca
//

import SwiftUI

/// Semantic color tokens for the "Literary Warmth" palette.
///
/// This is the only place in the app where a color is named. Values live as color
/// sets in `Assets.xcassets/DesignSystem`, each with a light and a dark variant, so
/// appearance switching needs no code. Never write a literal color anywhere else:
/// if a new one is needed, add a color set here and expose it as a case below.
enum AppColor {

    // MARK: Surfaces

    /// Page background, behind everything else.
    static let background = Color("Background")
    /// Raised surfaces: cards, sheets, grouped rows.
    static let surface = Color("Surface")
    /// Hairline separators and card outlines.
    static let borderSubtle = Color("BorderSubtle")

    // MARK: Content

    /// Titles and body copy.
    static let textPrimary = Color("TextPrimary")
    /// Supporting copy: authors, captions, metadata.
    static let textSecondary = Color("TextSecondary")

    // MARK: Brand

    /// Bottle green. Primary actions and selected states.
    static let brandPrimary = Color("BrandPrimary")
    /// Coral. Highlights and the active reading session.
    static let brandAccent = Color("BrandAccent")

    // MARK: Book status

    /// Color pairs for the four book statuses, used by status chips and badges.
    ///
    /// Deliberately not keyed by a domain type: the design system knows nothing
    /// about `Book`. Features map their own status enum onto these values.
    enum Status {
        static let wishlist = StatusPalette(
            background: Color("StatusWishlistBackground"),
            foreground: Color("StatusWishlistText")
        )
        static let owned = StatusPalette(
            background: Color("StatusOwnedBackground"),
            foreground: Color("StatusOwnedText")
        )
        static let reading = StatusPalette(
            background: Color("StatusReadingBackground"),
            foreground: Color("StatusReadingText")
        )
        static let finished = StatusPalette(
            background: Color("StatusFinishedBackground"),
            foreground: Color("StatusFinishedText")
        )
    }
}

/// A status color pair: a tinted fill with the matching readable foreground.
struct StatusPalette {
    let background: Color
    let foreground: Color
}
