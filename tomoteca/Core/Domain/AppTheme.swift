//
//  AppTheme.swift
//  tomoteca
//

import Foundation

/// Which appearance the reader wants, regardless of what the phone is doing.
///
/// `system` is the default and is what the app did before there was a choice: follow the phone.
enum AppTheme: Int, CaseIterable, Identifiable, Sendable {
    case system = 0
    case light = 1
    case dark = 2

    var id: Int { rawValue }
}
