//
//  tomotecaApp.swift
//  tomoteca
//
//  Created by Sergio Baudilio Pinilla Martinez on 11/08/26.
//

import SwiftUI
import CoreData

@main
struct tomotecaApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
