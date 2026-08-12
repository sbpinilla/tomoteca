//
//  Spacing.swift
//  tomoteca
//

import CoreGraphics

/// Spacing scale, on a 4pt grid.
///
/// Every padding, every stack spacing and every inset comes from here. A literal
/// number in a view means the scale was missing a step — add the step instead of
/// writing the number.
enum Spacing {
    /// 4 — tight pairs: an icon and its label.
    static let xs: CGFloat = 4
    /// 8 — inside a chip or a compact control.
    static let sm: CGFloat = 8
    /// 16 — the default: card padding, screen margins, row spacing.
    static let md: CGFloat = 16
    /// 24 — between groups of content.
    static let lg: CGFloat = 24
    /// 32 — between major sections.
    static let xl: CGFloat = 32
}
