//
//  CustomersCardView.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/11.
//

import SwiftData
import SwiftUI

struct CustomersCardView: View {
    @Environment(\.modelContext) var modelContext    
    @State private var customerCards = [Customers]()
    
    @State private var errorMessage: String?
    
    @State private var offset: Int = 0
    @State private var limit: Int = 50
    
    @State private var isLoading = false
    
    @State private var currentIndexKey: String? = nil
    @State private var lowerBoundName: String? = nil
    @State private var pendingScrollKeyForIndex: String? = nil
    @State private var stickToIdAfterPrepend: String? = nil
    
    // セクション化（五十音の行ごと）
    private var sectionedCards: [String: [Customers]] {
        let grouped = Dictionary(grouping: customerCards) { (card: Customers) in
            guard let first = card.name.first else { return "#" }
            return gojuonRow(for: first)
        }
        var sortedGrouped: [String: [Customers]] = [:]
        for (key, values) in grouped {
            sortedGrouped[key] = values.sorted { $0.name < $1.name }
        }
        return sortedGrouped
    }
    
    private var sortedSectionKeys: [String] {
        ["あ","か","さ","た","な","は","ま","や","ら","わ"]
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollViewReader { proxy in
                    List {
                        Color.red
                            .frame(height: 1)
                            .onAppear {
                                topSentinelAppear()
                            }
                        
                        ForEach(customerCards, id: \.name) { card in
                            CustomersCardRow(card: card)
                        }
                        
                        Color.blue
                            .frame(height: 1)
                            .onAppear {
                                buttomSentinelAppear()
                            }
                    }
                    .onChange(of: customerCards) {
                        // 上方向プリペンド後の位置復元
                        if let id = stickToIdAfterPrepend {
                            // 次のフレームでレイアウトが安定してから、追加分の最下部へスムーズに移動
                            Task { @MainActor in
                                await Task.yield()
                                withAnimation(.none) {
                                    proxy.scrollTo(id, anchor: .top)
                                }
                                stickToIdAfterPrepend = nil
                            }
                            return
                        }
                        
                        // インデックスジャンプ後のアンカーへスクロール
                        if let key = pendingScrollKeyForIndex {
                            let exists = customerCards.contains { card in
                                guard let first = card.name.first else { return false }
                                return gojuonRow(for: first) == key
                            }
                            if exists {
                                withAnimation(.easeInOut) {
                                    proxy.scrollTo(key, anchor: .top)
                                }
                                pendingScrollKeyForIndex = nil
                                // アンカー表示が完了したら、直前の行を少量だけプレビュー読み込み
                                preloadPreviousForAnchor(key)
                            }
                        }
                    }
                    .overlay(alignment: .trailing) {
                        IndexBar(keys: sortedSectionKeys, currentKey: $currentIndexKey) { key in
                            let anchorKey = gojuonRow(for: key.first ?? "あ")
                            let exists = customerCards.contains { card in
                                guard let first = card.name.first else { return false }
                                return gojuonRow(for: first) == anchorKey
                            }
                            if exists {
                                withAnimation(.easeInOut) {
                                    proxy.scrollTo(anchorKey, anchor: .top)
                                }
                                // 既に存在している場合でも前方プレビューを補う
                                preloadPreviousForAnchor(anchorKey)
                            } else {
                                lowerBoundName = anchorKey
                                pendingScrollKeyForIndex = anchorKey
                                topSentinelAppearLoadInitial()
                            }
                        }
                        .padding(.trailing, 4)
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
                CustomersRepository.createSharedInstance(modelContext: modelContext)
                loadInitial()
            }
            .navigationTitle("名刺一覧 \(pendingScrollKeyForIndex) 表示中: (\(customerCards.count))件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    HStack {
                        Menu {
                            Button("全て削除", role: .destructive) {
                                deleteAllData()
                            }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        
                        Menu {
                            Button("1,000件追加") { Customers.generateData(count: 1000) }
                            Button("10,000件追加") { Customers.generateData(count: 10000) }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
    }
    
    private func loadInitial() {
        guard !isLoading else { return }
        isLoading = true
        customerCards.removeAll()
        offset = 0
        Task {
            let repo = CustomersRepository.shared!
            let list = await repo.fetch(offset: offset, limit: limit, lower: lowerBoundName)
            await MainActor.run {
                customerCards = list
                offset += list.count
                isLoading = false
            }
        }
    }
    
    private func topSentinelAppearLoadInitial() {
        guard !isLoading else { return }
        isLoading = true
        customerCards.removeAll()
        offset = 0
        Task {
            let repo = CustomersRepository.shared!
            let list = await repo.fetch(offset: offset, limit: limit, lower: lowerBoundName)
            await MainActor.run {
                customerCards = list
                offset += list.count
                isLoading = false
            }
        }
    }
    
    private func topSentinelAppear() {
        guard !isLoading else { return }
        
        guard let first = customerCards.first else { return }
        guard let firstKey = first.name.first.map({ gojuonRow(for: $0) }) else { return }
        guard let prevKey = previousRowKey(for: firstKey) else { return }
        isLoading = true
        
        var descriptor = FetchDescriptor<Customers>(
            sortBy: [SortDescriptor(\Customers.name, order: .reverse)]
        )
        let lower = prevKey
        let upper = firstKey
        
        Task {
            let repo = CustomersRepository.shared!
            let fetched = repo.fetch(offset: 0, limit: 50, upper: firstKey, lower: prevKey)
            
            await MainActor.run {
                let existing = Set(customerCards.map { $0.name })
                let toInsert = fetched.filter { !existing.contains($0.name) }
                if !toInsert.isEmpty {
                    // プリペンド前に画面先頭に見えていた要素を復元アンカーとして保存
                    stickToIdAfterPrepend = first.name
                    customerCards.insert(contentsOf: toInsert, at: 0)
                }
                isLoading = false
            }
        }
    }
    
    private func buttomSentinelAppear() {
        guard !isLoading else { return }
        isLoading = true
        var descriptor = FetchDescriptor<Customers>(
            sortBy: [SortDescriptor(\Customers.name, order: .forward)]
        )
        if let bound = lowerBoundName {
            descriptor.predicate = #Predicate<Customers> { $0.name >= bound }
        }
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        Task {
            let next = (try? modelContext.fetch(descriptor)) ?? []
            await MainActor.run {
                if next.isEmpty {
                } else {
                    let existing = Set(customerCards.map { $0.name })
                    let toAppend = next.filter { !existing.contains($0.name) }
                    customerCards.append(contentsOf: toAppend)
                    offset += next.count
                }
                isLoading = false
            }
        }
    }
    
    private func gojuonRow(for firstChar: Character) -> String {
        switch firstChar {
        case "あ","い","う","え","お": return "あ"
        case "か","き","く","け","こ": return "か"
        case "さ","し","す","せ","そ": return "さ"
        case "た","ち","つ","て","と": return "た"
        case "な","に","ぬ","ね","の": return "な"
        case "は","ひ","ふ","へ","ほ": return "は"
        case "ま","み","む","め","も": return "ま"
        case "や","ゆ","よ": return "や"
        case "ら","り","る","れ","ろ": return "ら"
        case "わ","を","ん": return "わ"
        default: return ""
        }
    }
    
    private func previousRowKey(for row: String) -> String? {
        guard let idx = sortedSectionKeys.firstIndex(of: row), idx > 0 else { return nil }
        return sortedSectionKeys[idx - 1]
    }
    
    // アンカー行より少し前（直前の行の末尾側）を少量だけ読み込む
    private func preloadPreviousForAnchor(_ anchorKey: String) {
        guard let prevKey = previousRowKey(for: anchorKey) else { return }
        var descriptor = FetchDescriptor<Customers>(
            sortBy: [SortDescriptor(\Customers.name, order: .reverse)]
        )
        let lower = prevKey
        let upper = anchorKey
        descriptor.predicate = #Predicate<Customers> { card in
            card.name < upper && card.name >= lower
        }
        descriptor.fetchLimit = 12
        descriptor.fetchOffset = 0
        Task {
            let fetched = (try? modelContext.fetch(descriptor)) ?? []
            await MainActor.run {
                let existing = Set(customerCards.map { $0.name })
                let toAppend = fetched.filter { card in
                    guard let first = card.name.first else { return false }
                    return gojuonRow(for: first) == prevKey && !existing.contains(card.name)
                }
                if !toAppend.isEmpty {
                    customerCards.append(contentsOf: toAppend)
                }
            }
        }
    }
    
    
    func deleteAllData() {
        let repository = CustomersRepository.shared!
        Task.detached {
            do {
                try await repository.deleteAll()
                
                await MainActor.run {
                    errorMessage = nil
                    customerCards.removeAll()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "データの削除に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
}
