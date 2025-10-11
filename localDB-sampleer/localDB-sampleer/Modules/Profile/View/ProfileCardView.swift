//
//  ProfileCardView.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/11.
//

import SwiftData
import SwiftUI

struct ProfileCardView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \ProfileCard.name, order: .reverse) var profileCards: [ProfileCard]
    @State var errorMessage: String?
    @State var backgroundTotalCards: Int = 0
    @State var showDeleteAllAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 名刺リスト
                List {
                    ForEach(profileCards, id: \.name) { card in
//                        BusinessCardRow(card: card)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
//                            deleteBusinessCard(businessCards[index])
                        }
                    }
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color(.systemRed).opacity(0.1))
                }
            }
            .navigationTitle("名刺一覧 総名刺数: (\(backgroundTotalCards))枚")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    HStack {
                        Menu {
                            Button("1,000件削除", role: .destructive) { deleteBusinessCards(count: 1000) }
                            Button("5,000件削除", role: .destructive) { deleteBusinessCards(count: 5000) }
                            Button("10,000件削除", role: .destructive) { deleteBusinessCards(count: 10000) }
                            
                            Divider()
                            
                            Button("全て削除", role: .destructive) {
                                showDeleteAllAlert = true
                            }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        
                        Menu {
                            Button("1,000件追加") { addBusinessCards(count: 1000) }
                            Button("5,000件追加") { addBusinessCards(count: 5000) }
                            Button("10,000件追加") { addBusinessCards(count: 10000) }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .alert("全ての名刺を削除", isPresented: $showDeleteAllAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("削除", role: .destructive) {
                    deleteAllBusinessCards()
                }
            } message: {
                Text("全ての名刺（\(backgroundTotalCards)件）を削除しますか？この操作は取り消せません。")
            }
        }
    }
    
    func deleteBusinessCards(count: Int) {}
    func addBusinessCards(count: Int) {}
    func deleteAllBusinessCards() {}
}
