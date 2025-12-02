//
//  SimpleSearchListView.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/16.
//

import SwiftData
import SwiftUI

struct SimpleSearchListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SimpleObject.name, order: .forward) private var simpleDatas: [SimpleObject]
    @State private var searchText: String = ""
    @State private var isLoading = false
    
    // デバッグ用
    @State private var fetchMs: Double? = nil
    
    var searchResults: [SimpleObject] {
           if searchText.isEmpty {
               return simpleDatas
           } else {
               return simpleDatas.filter { $0.name.contains(searchText) }
           }
       }
  
    var body: some View {
        List {
            ForEach(searchResults, id: \.name) { card in
                Text(card.name)
            }
        }
        .overlay(alignment: .topTrailing) { PaformanceView() }
        .navigationTitle("\(simpleDatas.count)件")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) { ToolBarView() }
        }
        .searchable(text: $searchText)
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
