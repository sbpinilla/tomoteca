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
    private let sessionRepository: ReadingSessionRepository
    private let notifications: any SessionNotificationScheduling = Self.makeNotificationScheduler()

    init() {
        AppAppearance.configure()

        #if DEBUG
        if CommandLine.arguments.contains(PersistenceController.seedArgument) {
            persistenceController.seedSampleDataIfNeeded()
        }
        #endif

        bookRepository = CoreDataBookRepository(persistence: persistenceController)
        sessionRepository = CoreDataReadingSessionRepository(persistence: persistenceController)
    }

    /// The real scheduler, except in a UI test run: a system permission alert would sit on top
    /// of the app and stall every test behind it.
    private static func makeNotificationScheduler() -> any SessionNotificationScheduling {
        #if DEBUG
        if CommandLine.arguments.contains("-disableNotifications") {
            return NoOpNotificationScheduler()
        }
        #endif
        return SessionNotificationScheduler()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(
                bookRepository: bookRepository,
                sessionRepository: sessionRepository,
                notifications: notifications
            )
        }
    }
}
