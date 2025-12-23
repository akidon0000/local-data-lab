//
//  SimpleData_100K_ListView.swift
//  LocalDataLab
//
//  Created by Akihiro Matsuyama on 2025/10/16.
//

import Dispatch
import SwiftData
import SwiftUI

struct SimpleData_100K_ListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var simpleDatas: [SimpleData_100K_2] = []
    @State private var sections: [IndexedSection<SimpleData_100K_2, String>] = []
    @State private var searchText: String = ""
    @State private var isLoading = false
    
    // デバッグ用
    @State private var fetchMs: Double? = nil
    @State private var sectionMs: Double? = nil
    
    var searchResults: [SimpleData_100K_2] {
        if searchText.isEmpty {
            return simpleDatas
        } else {
            return simpleDatas.filter { $0.name.contains(searchText) }
        }
    }
    
    // 先頭文字ごとにセクションを構築（simpleDatas は name で昇順ソート済み）
//    private var sections: [IndexedSection<SimpleData_100K, String>] {
//        var result: [IndexedSection<SimpleData_100K, String>] = []
//        var currentKey: String? = nil
//        for item in searchResults {
//            let key = String(item.name.prefix(1))
//            if key != currentKey {
//                result.append(IndexedSection(key: key, items: []))
//                currentKey = key
//            }
//            if !result.isEmpty {
//                result[result.count - 1].items.append(item)
//            }
//        }
//        return result
//    }
  
    var body: some View {
        List {
            ForEach(sections, id: \.key) { section in
                Section(header: Text(section.key)) {
                    ForEach(section.items, id: \.id) { item in
                        Text(item.name)
                    }
                }
                .sectionIndexLabel(section.key)
            }
        }
        .overlay(alignment: .topTrailing) { PerformanceView() }
        .navigationTitle("\(simpleDatas.count)件")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) { ToolBarView() }
        }
        .searchable(text: $searchText)
        .onAppear { if simpleDatas.isEmpty { reload() } }
        .onChange(of: searchText) { _ in
            measureAndBuildSections()
        }
    }
    
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
            if let s = sectionMs {
                Text(String(format: "section/sort: %.1f ms", s))
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
                Button("10,000件追加") { generateData(count: 10000) }
                Button("100,000件追加") { generateData(count: 100000) }
            } label: {
                Image(systemName: "plus")
            }
            Button {
                reload()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
        }
    }
    
    private func deleteAllData() {
        do {
            try modelContext.delete(model: SimpleData_100K_2.self)
            reload()
        } catch {
            print(error)
        }
    }
    
    private func generateData(count: Int) {
        do {
            var items = [SimpleData_100K_2]()
            for _ in 0..<count {
                let nameSize = Int.random(in: 2...10)
                let randomName = HiraganaGenerator.makeRandomName(length: nameSize)
                let customer = SimpleData_100K_2(name: randomName)
                items.append(customer)
            }

            _ = items.map { modelContext.insert($0) }
            try modelContext.save()
            reload()
        } catch {
            print(error)
        }
    }

    // 先頭文字ごとにセクションを構築（items は name で昇順ソート済み想定）
    private func buildSections(from source: [SimpleData_100K_2]) -> [IndexedSection<SimpleData_100K_2, String>] {
        var result: [IndexedSection<SimpleData_100K_2, String>] = []
        var currentKey: String? = nil
        for item in source {
            let key = String(item.name.prefix(1))
            if key != currentKey {
                result.append(IndexedSection(key: key, items: []))
                currentKey = key
            }
            if !result.isEmpty {
                result[result.count - 1].items.append(item)
            }
        }
        return result
    }

    private func measureAndBuildSections() {
        let sectionStart = DispatchTime.now()
        let built = buildSections(from: searchResults)
        let sectionEnd = DispatchTime.now()
        let sectionDurationMs = Double(sectionEnd.uptimeNanoseconds - sectionStart.uptimeNanoseconds) / 1_000_000
        sections = built
        sectionMs = sectionDurationMs
    }

    private func reload() {
        guard !isLoading else { return }
        isLoading = true
        fetchMs = nil
        sectionMs = nil
        
        Task {
            // fetch
            let fetchStart = DispatchTime.now()
            var descriptor = FetchDescriptor<SimpleData_100K_2>(
                sortBy: [SortDescriptor(\SimpleData_100K_2.name, order: .forward)]
            )
            descriptor.includePendingChanges = true
            let fetched = (try? modelContext.fetch(descriptor)) ?? []
            let fetchEnd = DispatchTime.now()
            let fetchDurationMs = Double(fetchEnd.uptimeNanoseconds - fetchStart.uptimeNanoseconds) / 1_000_000
            
            await MainActor.run {
                simpleDatas = fetched
                fetchMs = fetchDurationMs
                // 検索条件を反映したセクションを計測・構築
                measureAndBuildSections()
                isLoading = false
            }
        }
    }
}
