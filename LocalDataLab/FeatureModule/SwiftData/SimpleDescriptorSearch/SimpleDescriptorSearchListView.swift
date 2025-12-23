//
//  SimpleDescriptorSearchListView.swift
//  LocalDataLab
//
//  Created by Akihiro Matsuyama on 2025/12/03.
//

import SwiftData
import SwiftUI
import SQLite3

struct SimpleDescriptorSearchListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchText: String = ""
    @State private var searchResults: [SimpleDescriptorObject] = []
    @State private var allDataCount: Int = 0
    @State private var isLoading = false
    @State private var fetchMs: Double? = nil

    var body: some View {
        List {
            ForEach(searchResults, id: \.id) { item in
                Text(item.name)
            }
        }
        .navigationTitle("\(allDataCount)件")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) { ToolBarView() }
        }
        .searchable(text: $searchText, prompt: "名前の前方一致で検索")
        .onChange(of: searchText) { _, newValue in
            performSearch(query: newValue)
        }
        .onAppear {
            loadAllData()
            performSearch(query: searchText)
        }
        .overlay(alignment: .topTrailing) { PerformanceView() }
    }

    // MARK: - Performance View
    @ViewBuilder
    private func PerformanceView() -> some View {
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
            Text("検索結果: \(searchResults.count)件")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(.ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: 8,
                                         style: .continuous))
        .padding(8)
    }

    // MARK: - Toolbar
    @ViewBuilder
    private func ToolBarView() -> some View {
        HStack {
            Button(action: {
                explainQuery()
            }) {
                Image(systemName: "info.circle")
            }

            Menu {
                Button("全て削除", role: .destructive) {
                    deleteAllData()
                }
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }

            Menu {
                Button("10,000件追加") { generateData(count: 10000) }
                Button("100,000件追加") { generateData(count: 100000) }
                Button("1,000,000件追加") { generateData(count: 1000000) }
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    // MARK: - Search with FetchDescriptor
    private func performSearch(query: String) {
        isLoading = true
        let startTime = CFAbsoluteTimeGetCurrent()

        Task {
            do {
                let descriptor: FetchDescriptor<SimpleDescriptorObject>

                if query.isEmpty {
                    // 検索クエリが空の場合は全件取得
                    descriptor = FetchDescriptor<SimpleDescriptorObject>(
                        sortBy: [SortDescriptor(\.name, order: .forward)]
                    )
                } else {
                    // 検索クエリがある場合はPredicateで絞り込み（前方一致）
                    descriptor = FetchDescriptor<SimpleDescriptorObject>(
                        predicate: #Predicate { object in
                            object.name.starts(with: query)
                        },
                        sortBy: [SortDescriptor(\.name, order: .forward)]
                    )
                }

                let results = try modelContext.fetch(descriptor)

                await MainActor.run {
                    searchResults = results
                    let endTime = CFAbsoluteTimeGetCurrent()
                    fetchMs = (endTime - startTime) * 1000
                    isLoading = false
                }
            } catch {
                print("検索エラー: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }

    private func loadAllData() {
        Task {
            do {
                let countDescriptor = FetchDescriptor<SimpleDescriptorObject>()
                let count = try modelContext.fetchCount(countDescriptor)
                await MainActor.run {
                    allDataCount = count
                }
            } catch {
                print("カウント取得エラー: \(error)")
            }
        }
    }

    // MARK: - Data Operations
    private func deleteAllData() {
        do {
            try modelContext.delete(model: SimpleDescriptorObject.self)
            loadAllData()
            performSearch(query: searchText)
        } catch {
            print("削除エラー: \(error)")
        }
    }

    private func generateData(count: Int) {
        isLoading = true
        Task {
            do {
                var items = [SimpleDescriptorObject]()
                for _ in 0..<count {
                    let nameSize = Int.random(in: 2...10)
                    let randomName = HiraganaGenerator.makeRandomName(length: nameSize)
                    let object = SimpleDescriptorObject(name: randomName)
                    items.append(object)
                }

                _ = items.map { modelContext.insert($0) }
                try modelContext.save()

                await MainActor.run {
                    loadAllData()
                    performSearch(query: searchText)
                    isLoading = false
                }
            } catch {
                print("データ生成エラー: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }

    // MARK: - Debug: Explain Query Plan
    private func explainQuery() {
        guard let url = modelContext.container.configurations.first?.url else {
            print("🚨 SQLite file URL not found")
            return
        }

        var db: OpaquePointer?

        if sqlite3_open(url.path, &db) == SQLITE_OK {
            let sql = """
            EXPLAIN QUERY PLAN
            SELECT * FROM ZSIMPLEDESCRIPTOROBJECT
            WHERE ZNAME LIKE 'あ%'
            ORDER BY ZNAME COLLATE BINARY;
            """

            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                print("📊 Query Plan:")
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let col0 = sqlite3_column_text(stmt, 0).map { String(cString: $0) } ?? ""
                    let col1 = sqlite3_column_text(stmt, 1).map { String(cString: $0) } ?? ""
                    let col2 = sqlite3_column_text(stmt, 2).map { String(cString: $0) } ?? ""
                    let col3 = sqlite3_column_text(stmt, 3).map { String(cString: $0) } ?? ""
                    print("  \(col0) | \(col1) | \(col2) | \(col3)")
                }
                sqlite3_finalize(stmt)
            } else {
                print("🚨 Failed to prepare statement")
            }
            sqlite3_close(db)
        } else {
            print("🚨 Failed to open database")
        }
    }
}
