//
//  SimpleDataInfiniteScrollView.swift
//  LocalDataLab
//
//  Created by Akihiro Matsuyama on 2025/10/18.
//

import SwiftData
import SwiftUI

struct SimpleDataInfiniteScrollView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var simpleObjects: [SimpleData_100K] = []
    @State private var searchText: String = ""
    
    var body: some View {
        List {
            ForEach(simpleObjects.enumerated(), id: \.element.id) { index, object in
                Text(object.name)
                    .onAppear {
                        let listCount = self.simpleObjects.count
                        if index >= listCount - 1 {
                            
                            var descriptor = FetchDescriptor<SimpleData_100K>(
                                sortBy: [SortDescriptor(\SimpleData_100K.name, order: .forward)]
                            )
                            descriptor.fetchOffset = listCount
                            descriptor.fetchLimit = 50
                            Task {
                                guard let nextLists = try? modelContext.fetch(descriptor) else { return }
                                await MainActor.run { simpleObjects.append(contentsOf: nextLists) }
                            }
                            
                        }
                    }
            }
        }
        .scrollIndicators(.hidden)
        .searchable(text: $searchText)
        .onChange(of: searchText) { _ in
            if !searchText.isEmpty {
//                measureAndBuildSections()
            }else{
                simpleObjects = []
                reload()
            }
        }
        .onAppear { if simpleObjects.isEmpty { reload() } }

        .navigationTitle("\(simpleObjects.count)件")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) { ToolBarView() }
        }
    }
    
    private func buttomSentinelAppear(offset: Int = 0, limit: Int = 50) {
//        guard !isLoading else { return }
//        isLoading = true
        var descriptor = FetchDescriptor<SimpleData_100K>(
            sortBy: [SortDescriptor(\SimpleData_100K.name, order: .forward)]
        )
        descriptor.fetchOffset = offset
        descriptor.fetchLimit = limit
        Task {
            let next = (try? modelContext.fetch(descriptor)) ?? []
            await MainActor.run {
                simpleObjects.append(contentsOf: next)
//                offset += next.count
//                isLoading = false
            }
        }
    }
    
    static func predicate(
        name: String
    ) -> Predicate<SimpleData_100K> {
        return #Predicate<SimpleData_100K> { school in
            school.name.starts(with: name)
        }
    }
    
    private func searchSimpleObjectsInStore(for searchText: String) {
        let predicate = #Predicate<SimpleData_100K> { school in
            school.name.starts(with: searchText)
        }
        
        let descriptor = FetchDescriptor<SimpleData_100K>(
            predicate: predicate,
            sortBy: [SortDescriptor(\SimpleData_100K.name, order: .forward)]
        )
        
        Task {
            guard let searchedLists = try? modelContext.fetch(descriptor) else { return }
            await MainActor.run { simpleObjects = searchedLists }
        }
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
            try modelContext.delete(model: SimpleData_100K.self)
            reload()
        } catch {
            print(error)
        }
    }
    
    private func generateData(count: Int) {
        do {
            var items = [SimpleData_100K]()
            for _ in 0..<count {
                let nameSize = Int.random(in: 2...10)
                let randomName = HiraganaGenerator.makeRandomName(length: nameSize)
                let customer = SimpleData_100K(name: randomName)
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
    private func buildSections(from source: [SimpleData_100K]) -> [IndexedSection<SimpleData_100K, String>] {
        var result: [IndexedSection<SimpleData_100K, String>] = []
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
    
//    private func measureAndBuildSections() {
//        let sectionStart = DispatchTime.now()
//        let built = buildSections(from: searchResults)
//        let sectionEnd = DispatchTime.now()
//        let sectionDurationMs = Double(sectionEnd.uptimeNanoseconds - sectionStart.uptimeNanoseconds) / 1_000_000
//        sections = built
//        sectionMs = sectionDurationMs
//    }


    private func reload() {
        Task {
            // fetch
            let fetchStart = DispatchTime.now()
            var descriptor = FetchDescriptor<SimpleData_100K>(
                sortBy: [SortDescriptor(\SimpleData_100K.name, order: .forward)]
            )
            descriptor.includePendingChanges = true
            descriptor.fetchLimit = 50
            let fetched = (try? modelContext.fetch(descriptor)) ?? []
            let fetchEnd = DispatchTime.now()
            let fetchDurationMs = Double(fetchEnd.uptimeNanoseconds - fetchStart.uptimeNanoseconds) / 1_000_000
            
            await MainActor.run {
                simpleObjects = fetched
                // 検索条件を反映したセクションを計測・構築
//                measureAndBuildSections()
            }
        }
    }
}
