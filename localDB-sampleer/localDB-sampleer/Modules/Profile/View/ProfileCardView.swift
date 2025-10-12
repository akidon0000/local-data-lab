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
    @State var showDeleteAllAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 名刺リスト
                List {
                    ForEach(profileCards, id: \.name) { card in
                        ProfileCardRow(card: card)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let cardToDelete = profileCards[index]
                            modelContext.delete(cardToDelete)
                            try? modelContext.save()
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
            .navigationTitle("名刺一覧 総名刺数: (\(profileCards.count))枚")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    HStack {
                        Menu {
                            Button("全て削除", role: .destructive) {
                                showDeleteAllAlert = true
                            }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        
                        Menu {
                            Button("1,000件追加") { generateData(count: 1000) }
                            Button("5,000件追加") { generateData(count: 5000) }
                            Button("10,000件追加") { generateData(count: 10000) }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .alert("全ての名刺を削除", isPresented: $showDeleteAllAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("削除", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("全ての名刺（\(profileCards.count)件）を削除しますか？この操作は取り消せません。")
            }
        }
    }
    
    func generateData(count: Int) {
        Task.detached {
            do {
                let repository = await ProfileCardRepository(modelContainer: modelContext.container)
                var list = [ProfileCard]()
                for i in 1...count {
                    let instance = ProfileCard(name: "User \(i)")
                    list.append(instance)
                }
                
                try await repository.create(todo: list)
                
                await MainActor.run {
                    errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = "データの生成に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func deleteAllData() {
        Task.detached {
            do {
                let repository = await ProfileCardRepository(modelContainer: modelContext.container)
                try await repository.deleteAll()
                
                await MainActor.run {
                    errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = "データの削除に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
}

