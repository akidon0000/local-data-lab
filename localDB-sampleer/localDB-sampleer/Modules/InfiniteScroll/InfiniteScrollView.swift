//
//  InfiniteScrollView.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/11.
//

import SwiftData
import SwiftUI

struct InfiniteScrollView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \BusinessCard.name, order: .reverse) var businessCards: [BusinessCard]
    @State var errorMessage: String?
    @State var isLoading = false
    @State var currentPage = 0
    @State var hasMoreData = true
    
    // 無限スクロール用のプロパティ
    let pageSize = 20

    var body: some View {
        NavigationView {
            VStack {
                if businessCards.isEmpty && !isLoading {
                    Text("名刺がありません")
                        .font(.title2)
                        .foregroundColor(.gray)
                } else {
                    // 名刺リスト
                    List {
                        ForEach(businessCards, id: \.name) { card in
                            BusinessCardRow(card: card)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                deleteBusinessCard(businessCards[index])
                            }
                        }

                        // ローディングインジケーター
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                        }
                    }
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("名刺一覧")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Button("サンプルデータを追加") {
                            generateSampleData()
                        }
                        
                        Button("大量サンプルデータを追加") {
                            generateLargeSampleData()
                        }
                        
                        Divider()
                        
                        Button("新しい名刺を追加") {
                            addBusinessCard(
                                name: "新しい名刺 \(Int.random(in: 1...999))",
                                company: "サンプル会社",
                                position: "役職"
                            )
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}
