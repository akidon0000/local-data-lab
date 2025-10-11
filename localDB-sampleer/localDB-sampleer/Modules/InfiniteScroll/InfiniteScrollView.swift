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
    @State var showDeleteAllAlert = false
    @State var backgroundTotalCards: Int = 0
    
    var totalCards: Int {
        businessCards.count
    }

    var body: some View {
        NavigationView {
            VStack() {
                HStack() {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("総名刺数: \(totalCards)枚")
                            .foregroundColor(.secondary)
                        
                        Text("バックグラウンド取得: \(backgroundTotalCards)枚")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                if businessCards.isEmpty && !isLoading {
                    Text("名刺がありません")
                        .font(.title2)
                        .foregroundColor(.gray)
                } else {
                    // 名刺リスト
//                    List {
//                        ForEach(businessCards, id: \.name) { card in
//                            BusinessCardRow(card: card)
//                        }
//                        .onDelete { indexSet in
//                            for index in indexSet {
//                                deleteBusinessCard(businessCards[index])
//                            }
//                        }
//
//                        // ローディングインジケーター
//                        if isLoading {
//                            HStack {
//                                Spacer()
//                                VStack(spacing: 8) {
//                                    ProgressView()
//                                    Text("処理中...")
//                                        .font(.caption)
//                                        .foregroundColor(.secondary)
//                                }
//                                .padding()
//                                Spacer()
//                            }
//                        }
//                    }
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color(.systemRed).opacity(0.1))
                }
            }
            .navigationTitle("名刺一覧")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    HStack {
                        // 削除メニュー
                        Menu {
                            // 一括削除メニュー
                            Menu("一括削除") {
                                Button("100件削除", role: .destructive) {
                                    deleteBusinessCards(count: 100)
                                }
                                
                                Button("500件削除", role: .destructive) {
                                    deleteBusinessCards(count: 500)
                                }
                                
                                Button("1,000件削除", role: .destructive) {
                                    deleteBusinessCards(count: 1000)
                                }
                                
                                Button("5,000件削除", role: .destructive) {
                                    deleteBusinessCards(count: 5000)
                                }
                                
                                Button("10,000件削除", role: .destructive) {
                                    deleteBusinessCards(count: 10000)
                                }
                            }
                            
                            Divider()
                            
                            Button("全て削除", role: .destructive) {
                                showDeleteAllAlert = true
                            }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .disabled(isLoading || businessCards.isEmpty)
                        
                        // 追加メニュー
                        Menu {
                            // 一括追加メニュー
                            Menu("一括追加") {
                                Button("100件追加") {
                                    addBusinessCards(count: 100)
                                }
                                
                                Button("500件追加") {
                                    addBusinessCards(count: 500)
                                }
                                
                                Button("1,000件追加") {
                                    addBusinessCards(count: 1000)
                                }
                                
                                Button("5,000件追加") {
                                    addBusinessCards(count: 5000)
                                }
                                
                                Button("10,000件追加") {
                                    addBusinessCards(count: 10000)
                                }
                            }
                            
                            Divider()
                            
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
                        .disabled(isLoading)
                    }
                }
            }
            .alert("全ての名刺を削除", isPresented: $showDeleteAllAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("削除", role: .destructive) {
                    deleteAllBusinessCards()
                }
            } message: {
                Text("全ての名刺（\(totalCards)件）を削除しますか？この操作は取り消せません。")
            }
//            .onAppear {
//                // バックグラウンドで総数を取得
//                loadBackgroundTotalCards()
//            }
        }
    }
    
    // MARK: - バックグラウンド処理
    
//    /// バックグラウンドで総名刺数を取得
//    private func loadBackgroundTotalCards() {
//        // 方法1: Task.detachedを使用
//        Task.detached { [modelContext] in
//            do {
//                let container = modelContext.container
//                let context = ModelContext(container)
//                let descriptor = FetchDescriptor<BusinessCard>()
//                let cards = try context.fetch(descriptor)
//                
//                await MainActor.run {
//                    backgroundTotalCards = cards.count
//                }
//                
//                print("Task.detachedで取得した総名刺数: \(cards.count)")
//            } catch {
//                print("バックグラウンドでの取得エラー: \(error)")
//            }
//        }
//        
//        // 方法2: BusinessCardRepositoryを使用
//        Task {
//            do {
//                let repository = BusinessCardRepository(modelContainer: modelContext.container)
//                let count = try await repository.getTotalCardsCount()
//                
//                await MainActor.run {
//                    // backgroundTotalCards = count // 上記のTask.detachedと重複するのでコメントアウト
//                }
//                
//                print("BusinessCardRepositoryで取得した総名刺数: \(count)")
//            } catch {
//                print("BusinessCardRepositoryでの取得エラー: \(error)")
//            }
//        }
//    }
}
