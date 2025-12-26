import Dispatch
import SwiftData
import SwiftUI

struct ComplexAllFetchListView: View {
    @Environment(\.modelContext) private var modelContext
    
    private let modelActor: ComplexDataModelActor
    
    init(simpleDataModelActor: ComplexDataModelActor) {
        self.modelActor = simpleDataModelActor
    }

    // 表示制御
    @State private var searchText: String = ""
    @State private var useAll: Bool = false

    // データ保持（プレビュー1000件／全件）
    @State private var previewSchools: [ComplexIndexSchool] = []
    @State private var allSchools: [ComplexIndexSchool] = []

    // ローディング／計測
    @State private var isLoadingPreview = false
    @State private var isLoadingAll = false
    @State private var fetchMsPreview: Double? = nil
    @State private var fetchMsAll: Double? = nil

    // IndexBar 現在キー
    @State private var currentIndexKey: String? = nil

    private var displayed: [ComplexIndexSchool] {
        if useAll, !allSchools.isEmpty { return allSchools }
        return previewSchools
    }

    private var searchResults: [ComplexIndexSchool] {
        let base = displayed
        guard !searchText.isEmpty else { return base }
        return base.filter { $0.name.contains(searchText) }
    }

    // 五十音行
    private var sortedSectionKeys: [String] {
        ["あ","か","さ","た","な","は","ま","や","ら","わ"]
    }

    // セクション構築（name の先頭を五十音行へ）
    private var sections: [IndexedSection<ComplexIndexSchool, String>] {
        buildSections(from: searchResults)
    }

    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                List {
                    ForEach(sections, id: \.key) { section in
                        Section {
                            ForEach(section.items.indices, id: \.self) { index in
                                let item = section.items[index]
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.headline)
                                    HStack(spacing: 8) {
                                        Text(item.location)
                                        Text(String(describing: item.type))
                                        Text("students: \(item.students.count)")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                                .id(item.id)
                            }
                        } header: {
                            Text(section.key)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .id(section.key)
                        }
                        .sectionIndexLabel(section.key)
                    }
                }
                .searchable(text: $searchText)
                .navigationTitle("\(displayed.count)件")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) { ToolBarView() }
                }
                .overlay(alignment: .topTrailing) { PerformanceView() }

                .onAppear { startDualFetch() }
            }
        }
    }

    @ViewBuilder
    private func PerformanceView() -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            if isLoadingAll || isLoadingPreview {
                HStack(spacing: 6) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.small)
                    Text(isLoadingAll ? "All Loading..." : "Loading...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if let p = fetchMsPreview {
                Text(String(format: "preview: %.1f ms", p))
                    .font(.caption2)
            }
            if let a = fetchMsAll {
                Text(String(format: "all: %.1f ms", a))
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
                Button("10件追加") { generateData(count: 10) }
                Button("100件追加") { generateData(count: 100) }
                Button("1,000件追加") { generateData(count: 1000) }
                Button("100,000件追加") { generateData(count: 100000) }
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    // MARK: - データ操作

    private func startDualFetch() {
        fetchPreview()
        fetchAllInBackground()
    }

    private func fetchPreview() {
        guard !isLoadingPreview else { return }
        isLoadingPreview = true
        fetchMsPreview = nil
        Task {
            let start = DispatchTime.now()
            var descriptor = FetchDescriptor<ComplexIndexSchool>(
                sortBy: [SortDescriptor(\ComplexIndexSchool.name, order: .forward)]
            )
            descriptor.fetchLimit = 1000
            descriptor.fetchOffset = 0
            descriptor.includePendingChanges = true
            let list = (try? modelContext.fetch(descriptor)) ?? []
            let end = DispatchTime.now()
            let elapsedMs = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
            await MainActor.run {
                previewSchools = list
                isLoadingPreview = false
                fetchMsPreview = elapsedMs
            }
        }
    }

    private func fetchAllInBackground() {
        guard !isLoadingAll else { return }
        isLoadingAll = true
        fetchMsAll = nil
        Task.detached(priority: .background) {
            let start = DispatchTime.now()
            // バックグラウンドではIDのみ取得（Sendable）
            let ids = (try? await modelActor.fetchAllComplexIndexSchoolIdsSortedByName()) ?? []
            // メインアクターでIDからフェッチ（UI更新と同一コンテキスト）
            await MainActor.run {
                var descriptor = FetchDescriptor<ComplexIndexSchool>(
                    sortBy: [SortDescriptor(\ComplexIndexSchool.name, order: .forward)]
                )
                descriptor.includePendingChanges = true
                let fetched: [ComplexIndexSchool] = (try? modelContext.fetch(descriptor)) ?? []
                // 取得済み一覧からIDでフィルタし、順序をID順で揃える
                let set = Set(ids)
                let filtered = fetched.filter { set.contains($0.id) }
                let end = DispatchTime.now()
                let elapsedMs = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
                allSchools = filtered
                useAll = true
                isLoadingAll = false
                fetchMsAll = elapsedMs
            }
        }
    }

    private func deleteAllData() {
        do {
            try modelContext.delete(model: ComplexIndexSchool.self)
            try modelContext.save()
        } catch {
            print(error)
        }
        // 表示をクリアして再取得
        previewSchools.removeAll()
        allSchools.removeAll()
        useAll = false
        startDualFetch()
    }

    private func generateData(count: Int) {
        Task {
            var created: [ComplexIndexSchool] = []
            for _ in 0..<count {
                if let school = try? ComplexIndexSchool() {
                    let studentCount = Int.random(in: 5..<21)
                    for _ in 0..<studentCount {
                        _ = try? ComplexIndexStudent(school: school)
                    }
                    created.append(school)
                }
            }
            _ = created.map { modelContext.insert($0) }
            do { try modelContext.save() } catch { print(error) }
            await MainActor.run {
                // 新規作成後に再取得
                previewSchools.removeAll()
                allSchools.removeAll()
                useAll = false
                startDualFetch()
            }
        }
    }

    // MARK: - セクション/インデックス補助

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
}
