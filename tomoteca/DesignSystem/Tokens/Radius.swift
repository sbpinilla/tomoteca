//
//  Radius.swift
//  tomoteca
//

import CoreGraphics

/// Corner radius scale.
enum Radius {
    /// 8 — small controls, thumbnails.
    static let sm: CGFloat = 8
    /// 12 — the default for cards and rows.
    static let md: CGFloat = 12
    /// 16 — sheets and large containers.
    static let lg: CGFloat = 16
    /// Fully rounded ends, for status chips and pill buttons.
    static let pill: CGFloat = 999
}
