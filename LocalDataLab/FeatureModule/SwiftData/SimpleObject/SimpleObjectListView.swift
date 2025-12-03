//
//  SimpleObjectListView.swift
//  LocalDataLab
//
//  Created by Akihiro Matsuyama on 2025/10/15.
//

import SwiftData
import SwiftUI

struct SimpleObjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SimpleObject.name, order: .reverse) private var simpleDatas: [SimpleObject]

    var body: some View {
        List {
            ForEach(simpleDatas, id: \.id) { card in
                Text(card.name)
            }
        }
        .navigationTitle("\(simpleDatas.count)件")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) { ToolBarView() }
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
                Button("1件追加") { generateData(count: 1) }
                Button("100件追加") { generateData(count: 100) }
                Button("1000件追加") { generateData(count: 1000) }
                Button("10000件追加") { generateData(count: 10000) }
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
            print("🚨", error)
        }
    }

    private func generateData(count: Int) {
        do {
            for _ in 0..<count {
                let customer = SimpleObject(name: "akidon")
                modelContext.insert(customer)
            }
            try modelContext.save()
        } catch {
            print("🚨", error)
        }
    }
}
