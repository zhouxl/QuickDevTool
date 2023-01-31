//
//  QuickDevToolApp.swift
//  QuickDevTool
//
//  Created by cat on 2023/1/31.
//

import SwiftUI

@main
struct QuickDevToolApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
