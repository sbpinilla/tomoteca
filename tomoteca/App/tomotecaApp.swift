//
//  tomotecaApp.swift
//  tomoteca
//

import SwiftUI

@main
struct tomotecaApp: App {

    /// Composition root: the stack is built here, wrapped in repositories, and only those
    /// travel down. Views never see a managed object context.
    private let persistenceController = PersistenceController.shared
    private let bookRepository: BookRepository

    init() {
        AppAppearance.configure()

        #if DEBUG
        if CommandLine.arguments.contains(PersistenceController.seedArgument) {
            persistenceController.seedSampleDataIfNeeded()
        }
        #endif

        bookRepository = CoreDataBookRepository(persistence: persistenceController)
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(bookRepository: bookRepository)
        }
    }
}
