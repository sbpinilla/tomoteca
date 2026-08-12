//
//  tomotecaApp.swift
//  tomoteca
//

import SwiftUI

@main
struct tomotecaApp: App {

    /// Loads the Core Data stack at launch. It is deliberately **not** pushed into the
    /// SwiftUI environment: views never touch a managed object context, they talk to a
    /// ViewModel, which talks to a repository. The repositories are the only holders
    /// of this container.
    private let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
    }
}
