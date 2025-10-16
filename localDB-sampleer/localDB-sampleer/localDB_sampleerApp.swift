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
            TabView {
                FewDataIndexView()
                    .tabItem {
                        Image(systemName: "list.bullet")
                        Text("Simple")
                    }
                FewDataView()
                    .tabItem {
                        Image(systemName: "list.number")
                        Text("Flat")
                    }
                FewDataIndexComplicatedView()
                    .tabItem {
                        Image(systemName: "person.text.rectangle")
                        Text("Complex")
                    }
            }
        }
        .modelContainer(for: [Customers.self, Company.self, Department.self, Address.self, Tag.self, Contact.self])
    }
}
