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
    private let sessionController: ActiveSessionController
    private let themeController: ThemeController
    private let notifications: any SessionNotificationScheduling = Self.makeNotificationScheduler()

    init() {
        AppAppearance.configure()

        #if DEBUG
        if CommandLine.arguments.contains(PersistenceController.seedArgument) {
            persistenceController.seedSampleDataIfNeeded()
        }

        // The remembered shelf and theme outlive the app, so without this one UI test would
        // decide where the next one opens, and in which appearance.
        if CommandLine.arguments.contains("-useInMemoryStore") {
            UserDefaults.standard.removeObject(forKey: BookListViewModel.selectedShelfKey)
            UserDefaults.standard.removeObject(forKey: ThemeController.storageKey)
        }
        #endif

        themeController = ThemeController()

        bookRepository = CoreDataBookRepository(persistence: persistenceController)
        let sessions = CoreDataReadingSessionRepository(persistence: persistenceController)
        sessionRepository = sessions

        // Built here so the session in progress belongs to the app, not to whichever screen
        // happened to start it — and so it is recovered on launch.
        sessionController = ActiveSessionController(
            bookRepository: bookRepository,
            sessionRepository: sessions,
            notifications: notifications,
            store: Self.makeActiveSessionStore()
        )
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

    /// UI runs get a throwaway store, so one test cannot leave a session behind for the next.
    private static func makeActiveSessionStore() -> any ActiveSessionStoring {
        #if DEBUG
        if CommandLine.arguments.contains("-useInMemoryStore") {
            return InMemoryActiveSessionStore()
        }
        #endif
        return ActiveSessionStore()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(
                bookRepository: bookRepository,
                sessionRepository: sessionRepository,
                notifications: notifications,
                sessionController: sessionController,
                themeController: themeController
            )
        }
    }
}
