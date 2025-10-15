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
    
    // ページング用 最初から{{offset}}件スキップ、{{limit}}件取得
    @State private var offset: Int = 0
    @State private var limit: Int = 50
    
    // ローディング状態
    @State private var isLoading = false
    
    // インデックスバーで現在指している行キー（五十音の「あ/か/...」）。UI表示用の状態
    @State private var currentIndexKey: String? = nil
    // ページング取得時の下限キー（このキー以上のデータを対象に読み込む）
    @State private var lowerBoundKey: String? = nil
    // インデックスジャンプ後に、対象行が読み込み済みになったらスクロールするアンカーキー
    @State private var pendingScrollAnchorKey: String? = nil
    // 上方向にデータをプリペンドした後、元の表示位置を復元するためのスクロールアンカーID（= 顧客名）
    @State private var stickToIDAfterPrepend: String? = nil
    
    
    @State private var visibleIndexes: Set<Int> = []   // いま画面に見えてる行
    @State private var lastMinIndex: Int? = nil        // 前回の最上位インデックス
    @State private var topCooldown = false             // 連打防止
    @State private var test: Int = 0 
    
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
    
    @State private var lastAppearedIndex: Int?
    @State private var lastDirectionIsUp = false
        
    var body: some View {
        NavigationView {
            ZStack {
                IndexedList(
                    items: customerCards,
                    id: \.name,
                    sectionKey: { card in
                        guard let first = card.name.first else { return "#" }
                        return gojuonRow(for: first)
                    },
                    keys: sortedSectionKeys,
                    currentIndexKey: $currentIndexKey,
                    pendingScrollAnchorKey: $pendingScrollAnchorKey,
                    stickToIDAfterPrepend: $stickToIDAfterPrepend,
                    row: { index, card in
                        CustomersCardRow(card: card)
                            .onAppear {
                                appear(index)
                                if index >= customerCards.count - 1 {
                                    buttomSentinelAppear()
                                }
                            }
                            .onDisappear { disappear(index) }
                    },
                    onSelectIndexKey: { key in
                        let anchorKey = gojuonRow(for: key.first ?? "あ")
                        let exists = customerCards.contains { card in
                            guard let first = card.name.first else { return false }
                            return gojuonRow(for: first) == anchorKey
                        }
                        if exists {
                            // 既に存在している場合でも前方プレビューを補う
                            pendingScrollAnchorKey = anchorKey
                            preloadPreviousForAnchor(anchorKey)
                        } else {
                            lowerBoundKey = anchorKey
                            pendingScrollAnchorKey = anchorKey
                            topSentinelAppearLoadInitial()
                        }
                    }
                )
                
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
            .navigationTitle("名刺一覧 \(test) 表示中: (\(customerCards.count))件")
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
    
    
    private func appear(_ index: Int) {
        visibleIndexes.insert(index)
        evaluateTopTrigger()
    }

    private func disappear(_ index: Int) {
        visibleIndexes.remove(index)
        evaluateTopTrigger()
    }

    private func evaluateTopTrigger() {
        guard let minNow = visibleIndexes.min() else { return }

        let scrollingUp = lastMinIndex.map { minNow < $0 } ?? false
        defer { lastMinIndex = minNow }

        // 「上にスクロール」かつ「先頭付近が見えてる」ときだけ実行
        if scrollingUp, minNow <= 2, !topCooldown {
            topCooldown = true
            Task {
                await topSentinelAppear()
                try? await Task.sleep(nanoseconds: 350_000_000) // 0.35s デバウンス
                topCooldown = false
            }
        }
    }
    
    private var sortedSectionKeys: [String] {
        ["あ","か","さ","た","な","は","ま","や","ら","わ"]
    }
    
    private func loadInitial() {
        guard !isLoading else { return }
        isLoading = true
        customerCards.removeAll()
        offset = 0
        Task {
            let repo = CustomersRepository.shared!
            let list = await repo.fetch(offset: offset, limit: limit, lower: lowerBoundKey)
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
            let list = await repo.fetch(offset: offset, limit: limit, lower: lowerBoundKey)
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
                    stickToIDAfterPrepend = first.name
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
        if let bound = lowerBoundKey {
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
