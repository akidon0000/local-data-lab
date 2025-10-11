//
//  localDB_sampleerApp.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/09/25.
//

import SwiftUI
import SwiftData

@main
struct localDB_sampleerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Trip.self,
            Accommodation.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            InfiniteScroll()
        }
//        .modelContainer(sharedModelContainer)
    }
}
