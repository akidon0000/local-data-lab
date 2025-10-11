//
//  ContentView.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/09/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                SectionText(
                    title: "",
                    subtitle: "各種データベースの実装を比較できます"
                )
                
                VStack(spacing: 16) {
                    // SwiftData
                    NavigationLink(destination: SwiftDataView().modelContainer(for: [
                        Trip.self,
                        Accommodation.self
                    ])) {
                        DatabaseOptionCard(
                            title: "SwiftData",
                            description: "Appleの最新データ永続化フレームワーク",
                            icon: "cylinder.fill",
                            color: .blue,
                            isAvailable: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // 将来的に追加予定のDB
                    DatabaseOptionCard(
                        title: "Core Data",
                        description: "従来のAppleデータ永続化フレームワーク",
                        icon: "externaldrive.fill",
                        color: .orange,
                        isAvailable: false
                    )
                    
                    DatabaseOptionCard(
                        title: "SQLite",
                        description: "軽量なリレーショナルデータベース",
                        icon: "table",
                        color: .green,
                        isAvailable: false
                    )
                    
                    DatabaseOptionCard(
                        title: "Realm",
                        description: "オブジェクト指向データベース",
                        icon: "globe",
                        color: .purple,
                        isAvailable: false
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationTitle("DB比較サンプル")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Trip.self,
            Accommodation.self
        ],
        inMemory: true)
}
