//
//  SimpleDataWrite_100K_ListView.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/16.
//

import SwiftData
import SwiftUI

struct SimpleDataWrite_100K_ListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SimpleData_100K.name, order: .forward) private var simpleDatas: [SimpleData_100K]
    @State private var isLoading = false
    
    // デバッグ用
    @State private var fetchMs: Double? = nil
    
    private let simpleDataModelActor: SimpleDataModelActor
    
    init(simpleDataModelActor: SimpleDataModelActor) {
        self.simpleDataModelActor = simpleDataModelActor
    }
  
    var body: some View {
        ZStack {
            Color.black
        }
        .overlay(alignment: .topTrailing) { PaformanceView() }
        .navigationTitle("\(simpleDatas.count)件")
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
    
    private func deleteAllData() {
        Task.detached(priority: .background) {
            await MainActor.run { isLoading = true }
            do {
                try await simpleDataModelActor.deleteAll()
            } catch {
                print(error)
            }
            await MainActor.run { isLoading = false }
        }
    }
    
    private func generateData(count: Int) {
        Task.detached(priority: .background) {
            await MainActor.run { isLoading = true }
            
            let batchSize = 2000
            var buffer = [String]()
            buffer.reserveCapacity(batchSize)
            for _ in 0..<count {
                let nameSize = Int.random(in: 2 ... 10)
                let randomName = await makeHiraganaName(nameSize)
                buffer.append(randomName)
                if buffer.count >= batchSize {
                    let items = buffer
                    do {
                        try await simpleDataModelActor.insert(names: items)
                    } catch {
                        print(error)
                    }
                    buffer.removeAll(keepingCapacity: true)
                    await Task.yield()
                }
            }
            if !buffer.isEmpty {
                let items = buffer
                do {
                    try await simpleDataModelActor.insert(names: items)
                } catch {
                    print(error)
                }
                buffer.removeAll(keepingCapacity: true)
            }
            await MainActor.run { isLoading = false }
        }
        
        // ランダムな名前を生成する関数（ひらがな）
        func makeHiraganaName(_ length: Int) async -> String {
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
