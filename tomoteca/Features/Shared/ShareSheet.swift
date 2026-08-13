//
//  ShareSheet.swift
//  tomoteca
//

import SwiftUI
import UIKit

/// The system share sheet.
///
/// `ShareLink` needs its item up front, and the export file only exists once the reader asks for
/// it. This is presented after the fact, with the file already written.
struct ShareSheet: UIViewControllerRepresentable {

    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
