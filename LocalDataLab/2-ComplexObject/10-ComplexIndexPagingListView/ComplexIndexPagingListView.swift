//
//  ComplexIndexPagingListView.swift
//  LocalDataLab
//
//  Created by Akihiro Matsuyama on 2025/10/16.
//

import SwiftData
import SwiftUI

struct ComplexIndexPagingListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var schools = [ComplexIndexSchool]()
    @State private var isLoading = false
    // ページング用 最初から{{offset}}件スキップ、{{limit}}件取得
    @State private var offset: Int = 0
    @State private var limit: Int = 50
    
    @State private var searchText: String = ""
    @State private var searchTask: Task<Void, Never>? = nil
    // インデックス/ページング補助
    @State private var currentIndexKey: String? = nil
    @State private var lowerBoundKey: String? = nil
    @State private var pendingScrollAnchorKey: String? = nil
    @State private var stickToIDAfterPrepend: String? = nil
    
    // デバッグ用
    @State private var fetchMs: Double? = nil
    
    var searchResults: [ComplexIndexSchool] {
        if searchText.isEmpty {
            return schools
        } else {
            return schools.filter { $0.name.contains(searchText) }
        }
    }

    private var sortedSectionKeys: [String] {
        ["あ","か","さ","た","な","は","ま","や","ら","わ"]
    }
    
    var body: some View {
        ZStack {
            SectionedIndexedList(
                sections: buildSections(from: searchResults),
                id: \.id,
                keys: sortedSectionKeys,
                currentIndexKey: $currentIndexKey,
                pendingScrollAnchorKey: $pendingScrollAnchorKey,
                stickToIDAfterPrepend: $stickToIDAfterPrepend,
                header: { key in
                    Text(key)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                },
                row: { _, school in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(school.name)
                            .font(.headline)
                        HStack(spacing: 8) {
                            Text(school.location)
                            Text(String(describing: school.type))
                            Text("students: \(school.students.count)")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .onAppear {
                        if let lastId = schools.last?.id, lastId == school.id {
                            buttomSentinelAppear()
                        }
                    }
                },
                onSelectIndexKey: { key in
                    let exists = schools.contains { s in
                        guard let first = s.name.first else { return false }
                        return gojuonRow(for: first) == key
                    }
                    if exists {
                        pendingScrollAnchorKey = key
                        preloadPreviousForAnchor(key)
                    } else {
                        lowerBoundKey = key
                        pendingScrollAnchorKey = key
                        topSentinelAppearLoadInitial()
                    }
                }
            )

            PaformanceView()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                IndexBar(keys: sortedSectionKeys, currentKey: $currentIndexKey) { key in
                    let exists = schools.contains { s in
                        guard let first = s.name.first else { return false }
                        return gojuonRow(for: first) == key
                    }
                    if exists {
                        pendingScrollAnchorKey = key
                        preloadPreviousForAnchor(key)
                    } else {
                        lowerBoundKey = key
                        pendingScrollAnchorKey = key
                        topSentinelAppearLoadInitial()
                    }
                }
                .padding(.trailing, 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            }
        }
        .searchable(text: $searchText)
        .onChange(of: searchText) { newValue in
            if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                searchTask?.cancel()
                offset = 0
                schools.removeAll()
                pendingScrollAnchorKey = nil
                lowerBoundKey = nil
                loadInitial()
            } else {
                performSearch(for: newValue)
            }
        }
        .onAppear {
            loadInitial()
        }
        .navigationTitle("\(schools.count)件")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) { ToolBarView() }
        }
    }
    
    @ViewBuilder
    private func PaformanceView() -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            if isLoading {
                HStack(spacing: 6) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.small)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if let f = fetchMs {
                Text(String(format: "fetch: %.1f ms", f))
                    .font(.caption2)
            }
        }
        .background(.ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: 8,
                                         style: .continuous))
        .padding(8)
    }
    
    @ViewBuilder
    private func ToolBarView() -> some View {
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
                Button("100件追加") { generateData(count: 100) }
                Button("1,000,000件追加") { generateData(count: 1000000) }
            } label: {
                Image(systemName: "plus")
            }
        }
    }
    
    private func loadInitial() {
        guard !isLoading else { return }
        isLoading = true
        Task {
            var descriptor = FetchDescriptor<ComplexIndexSchool>(
                sortBy: [SortDescriptor(\ComplexIndexSchool.name, order: .forward)]
            )
            if let bound = lowerBoundKey {
                descriptor.predicate = #Predicate<ComplexIndexSchool> { $0.name >= bound }
            }
            descriptor.fetchLimit = limit
            descriptor.fetchOffset = offset
            let list = (try? modelContext.fetch(descriptor)) ?? []
            await MainActor.run {
                schools = list
                offset += list.count
                isLoading = false
            }
        }
    }
    
    private func buttomSentinelAppear() {
        // 検索中はページングしない
        guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isLoading else { return }
        isLoading = true
        var descriptor = FetchDescriptor<ComplexIndexSchool>(
            sortBy: [SortDescriptor(\ComplexIndexSchool.name, order: .forward)]
        )
        if let bound = lowerBoundKey {
            descriptor.predicate = #Predicate<ComplexIndexSchool> { $0.name >= bound }
        }
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        Task {
            let next = (try? modelContext.fetch(descriptor)) ?? []
            await MainActor.run {
                if !next.isEmpty {
                    let existing = Set(schools.map { $0.id })
                    let toAppend = next.filter { !existing.contains($0.id) }
                    schools.append(contentsOf: toAppend)
                    offset += next.count
                }
                isLoading = false
            }
        }
    }
    
    private func performSearch(for query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        searchTask = Task {
            // 軽いデバウンス（タイプ中の過剰なクエリを抑制）
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }
            let start = CFAbsoluteTimeGetCurrent()
            var descriptor = FetchDescriptor<ComplexIndexSchool>(
                predicate: ComplexIndexSchool.predicate(name: trimmed),
                sortBy: [SortDescriptor(\ComplexIndexSchool.name, order: .forward)]
            )
            descriptor.fetchLimit = limit
            descriptor.fetchOffset = 0
            let list = (try? modelContext.fetch(descriptor)) ?? []
            let elapsedMs = (CFAbsoluteTimeGetCurrent() - start) * 1000
            await MainActor.run {
                self.schools = list
                self.offset = list.count
                self.fetchMs = elapsedMs
                self.isLoading = false
                // 検索時はサイドインデックス操作を無効化
                self.pendingScrollAnchorKey = nil
                self.lowerBoundKey = nil
            }
        }
    }

    // MARK: - インデックス/セクション関連

    private func buildSections(from items: [ComplexIndexSchool]) -> [IndexedSection<ComplexIndexSchool, String>] {
        var dict: [String: [ComplexIndexSchool]] = [:]
        for item in items {
            let key: String = {
                guard let first = item.name.first else { return "#" }
                return gojuonRow(for: first)
            }()
            dict[key, default: []].append(item)
        }
        var result: [IndexedSection<ComplexIndexSchool, String>] = []
        for key in sortedSectionKeys {
            if var arr = dict[key] {
                arr.sort { $0.name < $1.name }
                result.append(IndexedSection<ComplexIndexSchool, String>(key: key, items: arr))
            }
        }
        for (key, arr) in dict where !sortedSectionKeys.contains(key) {
            let sorted = arr.sorted { $0.name < $1.name }
            result.append(IndexedSection<ComplexIndexSchool, String>(key: key, items: sorted))
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

    private func preloadPreviousForAnchor(_ anchorKey: String) {
        guard !isLoading else { return }
        guard let prevKey = previousRowKey(for: anchorKey) else { return }
        var descriptor = FetchDescriptor<ComplexIndexSchool>(
            sortBy: [SortDescriptor(\ComplexIndexSchool.name, order: .reverse)]
        )
        let lower = prevKey
        let upper = anchorKey
        descriptor.predicate = #Predicate<ComplexIndexSchool> { school in
            school.name < upper && school.name >= lower
        }
        descriptor.fetchLimit = 12
        descriptor.fetchOffset = 0
        Task {
            let fetched = (try? modelContext.fetch(descriptor)) ?? []
            await MainActor.run {
                let existing = Set(schools.map { $0.id })
                let toAppend = fetched.filter { sch in
                    guard let first = sch.name.first else { return false }
                    return gojuonRow(for: first) == prevKey && !existing.contains(sch.id)
                }
                if !toAppend.isEmpty {
                    schools.append(contentsOf: toAppend)
                }
            }
        }
    }

    private func topSentinelAppearLoadInitial() {
        guard !isLoading else { return }
        isLoading = true
        schools.removeAll()
        offset = 0
        Task {
            var descriptor = FetchDescriptor<ComplexIndexSchool>(
                sortBy: [SortDescriptor(\ComplexIndexSchool.name, order: .forward)]
            )
            if let bound = lowerBoundKey {
                descriptor.predicate = #Predicate<ComplexIndexSchool> { $0.name >= bound }
            }
            descriptor.fetchLimit = limit
            descriptor.fetchOffset = offset
            let list = (try? modelContext.fetch(descriptor)) ?? []
            await MainActor.run {
                schools = list
                offset += list.count
                isLoading = false
            }
        }
    }
    
    private func deleteAllData() {
        do {
            try modelContext.delete(model: SimpleObject.self)
        } catch {
            print(error)
        }
    }
    
    private func generateData(count: Int) {
        do {
            var items = [SimpleObject]()
            for _ in 0..<count {
                let nameSize = Int.random(in: 2 ... 10)
                let randomName = makeHiraganaName(nameSize)
                let customer = SimpleObject(name: randomName)
                items.append(customer)
            }
            
            _ = items.map { modelContext.insert($0) }
            try modelContext.save()
        } catch {
            print(error)
        }
        
        // ランダムな名前を生成する関数（ひらがな）
        func makeHiraganaName(_ length: Int) -> String {
            let chars: [Character] = Array("あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん")
            var result = String()
            for _ in 0..<length {
                // 45音 + ん = 46文字
                let pos = Int.random(in: 0..<46)
                result.append(chars[pos])
            }
            return result
        }
    }
}
