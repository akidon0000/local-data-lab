//
//  SimpleObjectListView.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/15.
//

import SwiftData
import SwiftUI

struct SimpleObjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SimpleObject.name, order: .forward) private var simpleDatas: [SimpleObject]
    @State private var showMetricsAlert: Bool = false
    @State private var metricsText: String = ""
  
    var body: some View {
        List {
            ForEach(simpleDatas, id: \.name) { card in
                Text(card.name)
            }
        }
        .navigationTitle("\(simpleDatas.count)件")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) { ToolBarView() }
        }
        .alert("計測結果", isPresented: $showMetricsAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(metricsText)
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
                Button("100,000件追加") { generateData(count: 100000) }
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
        let t0 = DispatchTime.now()
        do {
            var items = [SimpleObject]()
            for _ in 0..<count {
                let customer = SimpleObject(name: "akidon")
                items.append(customer)
            }
            let t1 = DispatchTime.now()
            
            _ = items.map { modelContext.insert($0) }
            let t2 = DispatchTime.now()
            
            try modelContext.save()
            let t3 = DispatchTime.now()
            
            let createMs = Double(t1.uptimeNanoseconds - t0.uptimeNanoseconds) / 1_000_000
            let insertMs = Double(t2.uptimeNanoseconds - t1.uptimeNanoseconds) / 1_000_000
            let saveMs = Double(t3.uptimeNanoseconds - t2.uptimeNanoseconds) / 1_000_000
            let totalMs = Double(t3.uptimeNanoseconds - t0.uptimeNanoseconds) / 1_000_000
            
            let message = String(format: "生成: %.1fms\n挿入: %.1fms\n保存: %.1fms\n合計: %.1fms\n件数: %d", createMs, insertMs, saveMs, totalMs, count)
            print(message)
            metricsText = message
            showMetricsAlert = true
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
