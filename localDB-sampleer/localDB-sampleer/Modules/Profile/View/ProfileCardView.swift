//
//  ProfileCardView.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/11.
//

import SwiftData
import SwiftUI

struct ProfileModel {
    let name: Date
}

struct ProfileCardView: View {
    @Environment(\.modelContext) var modelContext
//    @Query(sort: \ProfileCard.name, order: .reverse) var profileCards: [ProfileCard]
//    @State var profileCards = [ProfileCard]()
    
//    static let profileCardsFilter = #Predicate<ProfileModel> { item in
//        return item.name == "User 145"
//    }
//    init(
//        searchText: String = ""
//    ) {
//        _profileCards = Query(
//            filter: ProfileCard.predicate(name: "User 145"),
//            sort: \ProfileCard.name,
//            order: .reverse
//        )
//    }
//    static func profileCardsFilter(
//        searchText: String,
//        searchDate: Date
//    ) -> Predicate<ProfileModel> {
        // 絞り込みを行う部分
//        let predicate = ProfileModel.predicate(name: String)
//        _profileCards = Query(filter: predicate, sort: \.name, order: .reverse)
//        let calendar = Calendar.autoupdatingCurrent
//        let start = calendar.startOfDay(for: searchDate)
//        let end = calendar.date(byAdding: .init(day: 1), to: start) ?? start
//
//
//        return #Predicate<Quake> { quake in
//            (searchText.isEmpty || quake.location.name.contains(searchText))
//            &&
//            (quake.time > start && quake.time < end)
//        }
//    }
    
    
    @State private var cursorDate: Date? = nil
    @State private var displayedCards: [ProfileCard] = []
    @State private var isLoading = false
    @State private var allDataLoaded = false
    private static let pageSize = 50
    
    
    @State var errorMessage: String?
    @State var showDeleteAllAlert = false
    @State var limit: Int = 50
    @State private var offset: Int = 0
    
    private func loadInitial() {
        guard !isLoading else { return }
        isLoading = true
        displayedCards.removeAll()
        allDataLoaded = false
        offset = 0
        var descriptor = FetchDescriptor<ProfileCard>(
            predicate: ProfileCard.predicate(name: "User 145"),
            sortBy: [SortDescriptor(\ProfileCard.name, order: .forward)]
        )
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        Task {
            let page = (try? modelContext.fetch(descriptor)) ?? []
            await MainActor.run {
                displayedCards = page
                offset += page.count
                allDataLoaded = page.count < limit
                isLoading = false
            }
        }
    }
    
    private func loadMore() {
        guard !isLoading, !allDataLoaded else { return }
        isLoading = true
        var descriptor = FetchDescriptor<ProfileCard>(
            predicate: ProfileCard.predicate(name: "User 145"),
            sortBy: [SortDescriptor(\ProfileCard.name, order: .forward)]
        )
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        Task {
            let next = (try? modelContext.fetch(descriptor)) ?? []
            await MainActor.run {
                if next.isEmpty {
                    allDataLoaded = true
                } else {
                    let existing = Set(displayedCards.map { $0.name })
                    let toAppend = next.filter { !existing.contains($0.name) }
                    displayedCards.append(contentsOf: toAppend)
                    offset += next.count
                }
                isLoading = false
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                
                
                // 名刺リスト
                List {
                    ForEach(displayedCards, id: \.name) { card in
                        ProfileCardRow(card: card)
                    }
                    if !allDataLoaded {
                        HStack {
                            Spacer()
                            ProgressView()
                                .onAppear {
                                    loadMore()
                                }
                            Spacer()
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
            .onAppear {
                ProfileCardRepository.createSharedInstance(modelContext: modelContext)
                loadInitial()
            }
            .navigationTitle("名刺一覧 表示中: (\(displayedCards.count))件")
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
                        Button("更新", role: .destructive) {
                            loadInitial()
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
                Text("全ての名刺（\(displayedCards.count)件）を削除しますか？この操作は取り消せません。")
            }
        }
    }
    
    func generateData(count: Int) {
        let repository = ProfileCardRepository.shared!
        Task.detached {
                var list = [ProfileCard]()
                for i in 1...count {
                    let instance = ProfileCard(name: "User \(i)")
                    list.append(instance)
                }
                
            do {
                try await repository.create(todo: list)
                await MainActor.run {
                    errorMessage = nil
                    // 新規作成後はカーソルと表示をリセット
                    cursorDate = nil
                    displayedCards.removeAll()
                    allDataLoaded = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "データの生成に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func deleteAllData() {
        let repository = ProfileCardRepository.shared!
        Task.detached {
            do {
                try await repository.deleteAll()
                
                await MainActor.run {
                    errorMessage = nil
                    // 削除後は状態をリセット
                    cursorDate = nil
                    displayedCards.removeAll()
                    allDataLoaded = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "データの削除に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
}

