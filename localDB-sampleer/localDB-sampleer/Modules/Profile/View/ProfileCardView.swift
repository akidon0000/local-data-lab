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
    @State private var displayedCards: [ProfileCard] = []
    
    @State var errorMessage: String?
    @State var showDeleteAllAlert = false
    @State var limit: Int = 50
    @State private var offset: Int = 0
    @State private var currentIndexKey: String? = nil
    @State private var cursorDate: Date? = nil
    @State private var isLoading = false
    @State private var allDataLoaded = false
    @State private var lowerBoundName: String? = nil
    @State private var pendingScrollKeyForIndex: String? = nil
    @State private var isLoadingPrevious = false
    @State private var ignoreInitialTopSentinel = true
    @State private var stickToIdAfterPrepend: String? = nil
    private static let pageSize = 50
    private let prefetchPreviousLimit = 12
    
    // セクション化（五十音の行ごと）
    private var sectionedCards: [String: [ProfileCard]] {
        let grouped = Dictionary(grouping: displayedCards) { (card: ProfileCard) in
            guard let first = card.name.first else { return "#" }
            return gojuonRow(for: first)
        }
        var sortedGrouped: [String: [ProfileCard]] = [:]
        for (key, values) in grouped {
            sortedGrouped[key] = values.sorted { $0.name < $1.name }
        }
        return sortedGrouped
    }
    
    private var sortedSectionKeys: [String] {
        ["あ","か","さ","た","な","は","ま","や","ら","わ"]
    }
    
    // 実データに存在するセクションのみをインデックス表示
    private var availableSectionKeys: [String] {
        let existing = Set(displayedCards.compactMap { $0.name.first.map { gojuonRow(for: $0) } })
        return sortedSectionKeys.filter { existing.contains($0) }
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
                        
                        ForEach(displayedCards, id: \.name) { card in
                            ProfileCardRow(card: card)
                        }
                        
                        Color.blue
                            .frame(height: 1)
                            .onAppear {
                                buttomSentinelAppear()
                            }
                    }
                    .onChange(of: displayedCards) {
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
                        
                        // 2) インデックスジャンプ後のアンカーへスクロール
                        if let key = pendingScrollKeyForIndex {
                            let exists = displayedCards.contains { card in
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
                            let exists = displayedCards.contains { card in
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
                ProfileCardRepository.createSharedInstance(modelContext: modelContext)
                loadInitial()
            }
            .navigationTitle("名刺一覧 \(pendingScrollKeyForIndex) 表示中: (\(displayedCards.count))件")
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
    
    private func loadInitial() {
        guard !isLoading else { return }
        isLoading = true
        displayedCards.removeAll()
        allDataLoaded = false
        offset = 0
        Task {
            let repo = ProfileCardRepository.shared!
            let list = await repo.fetch(offset: offset, limit: limit, lower: lowerBoundName)
            await MainActor.run {
                displayedCards = list
                offset += list.count
                allDataLoaded = list.count < limit
                isLoading = false
            }
        }
    }
    
    private func topSentinelAppearLoadInitial() {
        guard !isLoading else { return }
        isLoading = true
        displayedCards.removeAll()
        allDataLoaded = false
        offset = 0
        Task {
            let repo = ProfileCardRepository.shared!
            let list = await repo.fetch(offset: offset, limit: limit, lower: lowerBoundName)
            await MainActor.run {
                displayedCards = list
                offset += list.count
                allDataLoaded = list.count < limit
                isLoading = false
            }
        }
    }
    
    private func topSentinelAppear() {
        guard !isLoadingPrevious else { return }
        
        guard let first = displayedCards.first else { return }
        guard let firstKey = first.name.first.map({ gojuonRow(for: $0) }) else { return }
        guard let prevKey = previousRowKey(for: firstKey) else { return }
        isLoadingPrevious = true
        
        var descriptor = FetchDescriptor<ProfileCard>(
            sortBy: [SortDescriptor(\ProfileCard.name, order: .reverse)]
        )
        let lower = prevKey
        let upper = firstKey
        
        Task {
            let repo = ProfileCardRepository.shared!
            let fetched = repo.fetch(offset: 0, limit: Self.pageSize, upper: firstKey, lower: prevKey)
            
            await MainActor.run {
                let existing = Set(displayedCards.map { $0.name })
                let toInsert = fetched.filter { !existing.contains($0.name) }
                if !toInsert.isEmpty {
                    // プリペンド前に画面先頭に見えていた要素を復元アンカーとして保存
                    stickToIdAfterPrepend = first.name
                    displayedCards.insert(contentsOf: toInsert, at: 0)
                }
                isLoadingPrevious = false
            }
        }
    }
    
    private func buttomSentinelAppear() {
        guard !isLoading, !allDataLoaded else { return }
        isLoading = true
        var descriptor = FetchDescriptor<ProfileCard>(
            sortBy: [SortDescriptor(\ProfileCard.name, order: .forward)]
        )
        if let bound = lowerBoundName {
            descriptor.predicate = #Predicate<ProfileCard> { $0.name >= bound }
        }
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
    
    func generateData(count: Int) {
        let repository = ProfileCardRepository.shared!
        Task.detached {
            var list = [ProfileCard]()
            for i in 1...count {
                let instance = ProfileCard(name: makeHiraganaName(i))
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
    
    private func makeHiraganaName(_ index: Int) -> String {
        let chars: [Character] = Array("あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん")
        let length = 3 + (index % 3) // 3〜5文字
        var result = String()
        var seed = index
        for i in 0..<length {
            let pos = (seed + i * 7) % chars.count
            result.append(chars[pos])
        }
        return result
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
        var descriptor = FetchDescriptor<ProfileCard>(
            sortBy: [SortDescriptor(\ProfileCard.name, order: .reverse)]
        )
        let lower = prevKey
        let upper = anchorKey
        descriptor.predicate = #Predicate<ProfileCard> { card in
            card.name < upper && card.name >= lower
        }
        descriptor.fetchLimit = prefetchPreviousLimit
        descriptor.fetchOffset = 0
        Task {
            let fetched = (try? modelContext.fetch(descriptor)) ?? []
            await MainActor.run {
                let existing = Set(displayedCards.map { $0.name })
                let toAppend = fetched.filter { card in
                    guard let first = card.name.first else { return false }
                    return gojuonRow(for: first) == prevKey && !existing.contains(card.name)
                }
                if !toAppend.isEmpty {
                    displayedCards.append(contentsOf: toAppend)
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

// 右端インデックスバー
private struct IndexBar: View {
    let keys: [String]
    @Binding var currentKey: String?
    var onSelect: (String) -> Void
    @State private var contentHeight: CGFloat = 1
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(keys, id: \.self) { key in
                Text(key)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 14)
            }
        }
        .padding(.vertical, 6)
        .frame(width: 28)
        .background(.ultraThinMaterial, in: Capsule())
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { contentHeight = max(1, proxy.size.height) }
                    .onChange(of: proxy.size.height) { newValue in
                        contentHeight = max(1, newValue)
                    }
            }
        )
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard !keys.isEmpty else { return }
                    let locationY = max(0, min(contentHeight, value.location.y))
                    let idxFloat = (locationY / contentHeight) * CGFloat(max(1, keys.count))
                    let index = Int(idxFloat)
                    let clamped = max(0, min(keys.count - 1, index))
                    let key = keys[clamped]
                    if currentKey != key {
                        currentKey = key
                        onSelect(key)
                    }
                }
                .onEnded { value in
                    guard !keys.isEmpty else { return }
                    let locationY = max(0, min(contentHeight, value.location.y))
                    let idxFloat = (locationY / contentHeight) * CGFloat(max(1, keys.count))
                    let index = Int(idxFloat)
                    let clamped = max(0, min(keys.count - 1, index))
                    let key = keys[clamped]
                    if currentKey != key {
                        currentKey = key
                    }
                    onSelect(key)
                }
        )
    }
}

