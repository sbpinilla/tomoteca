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
    /// Recessed troughs: the segmented control's track, the unfilled part of a progress bar.
    static let track = Color("Track")

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

    /// One color per book status. Status is shown as colored text and a dot, never as
    /// a filled pill — that is what the approved design does, so there are no tinted
    /// background tokens to pair these with.
    ///
    /// Deliberately not keyed by a domain type: the design system knows nothing about
    /// `Book`. Features map their own status enum onto these values.
    enum Status {
        static let wishlist = Color("StatusWishlist")
        static let owned = Color("StatusOwned")
        static let reading = Color("StatusReading")
        static let finished = Color("StatusFinished")
    }
}
