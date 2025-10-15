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
    var body: some Scene {
        WindowGroup {
            FewDataView()
        }
        .modelContainer(for: Customers.self)
    }
}
