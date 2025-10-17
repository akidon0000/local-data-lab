//
//  SimpleIndexListView.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/16.
//

import SwiftData
import SwiftUI

struct SimpleIndexLabelListView: View {
    @Environment(\.modelContext) 
    private var modelContext
    
    @Query(sort: \SimpleObject.name, order: .forward)
    private var simpleDatas: [SimpleObject]
    
    @State private var searchText: String = ""
    
    var searchResults: [SimpleObject] {
        if searchText.isEmpty {
            return simpleDatas
        } else {
            return simpleDatas.filter { $0.name.contains(searchText) }
        }
    }
    
    // 先頭文字ごとにセクションを構築（simpleDatas は name で昇順ソート済み）
    private var sections: [IndexedSection<SimpleObject, String>] {
        var result: [IndexedSection<SimpleObject, String>] = []
        var currentKey: String? = nil
        for item in searchResults {
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
        .navigationTitle("\(simpleDatas.count)件")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) { ToolBarView() }
        }
        .searchable(text: $searchText)
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
                Button("10,000件追加") { generateData(count: 10000) }
                Button("1,000,000件追加") { generateData(count: 1000000) }
            } label: {
                Image(systemName: "plus")
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
