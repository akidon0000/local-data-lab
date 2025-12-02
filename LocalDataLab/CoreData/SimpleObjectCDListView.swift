//
//  SimpleObjectCDListView.swift
//  LocalDataLab
//
//  Created by Claude Code
//

import CoreData
import SwiftUI

struct SimpleObjectCDListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SimpleObjectCD.name, ascending: true)],
        animation: .default)
    private var simpleDatas: FetchedResults<SimpleObjectCD>

    @State private var showMetricsAlert: Bool = false
    @State private var metricsText: String = ""

    var body: some View {
        List {
            ForEach(simpleDatas) { item in
                Text(item.name)
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
                Button("1件追加") { generateData(count: 1) }
                Button("100件追加") { generateData(count: 100) }
                Button("100,000件追加") { generateData(count: 100000) }
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    private func deleteAllData() {
        do {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = SimpleObjectCD.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try viewContext.execute(deleteRequest)
            try viewContext.save()
        } catch {
            print(error)
        }
    }

    private func generateData(count: Int) {
        let t0 = DispatchTime.now()
        do {
            // バックグラウンドコンテキストを使用
            let backgroundContext = PersistenceController.shared.container.newBackgroundContext()
            backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

            var items = [SimpleObjectCD]()
            for _ in 0..<count {
                let newItem = SimpleObjectCD(context: backgroundContext)
                newItem.id = UUID().uuidString
                newItem.name = "akidon"
                items.append(newItem)
            }
            let t1 = DispatchTime.now()

            // Core Dataの場合、insertはcontext生成時に自動的に行われる
            let t2 = DispatchTime.now()

            try backgroundContext.save()
            let t3 = DispatchTime.now()

            let createMs = Double(t1.uptimeNanoseconds - t0.uptimeNanoseconds) / 1_000_000
            let insertMs = Double(t2.uptimeNanoseconds - t1.uptimeNanoseconds) / 1_000_000
            let saveMs = Double(t3.uptimeNanoseconds - t2.uptimeNanoseconds) / 1_000_000
            let totalMs = Double(t3.uptimeNanoseconds - t0.uptimeNanoseconds) / 1_000_000

            let message = String(format: "生成: %.1fms\n挿入: %.1fms\n保存: %.1fms\n合計: %.1fms\n件数: %d", createMs, insertMs, saveMs, totalMs, count)
//            print(message)

            DispatchQueue.main.async {
                metricsText = message
                showMetricsAlert = true
            }
        } catch {
            print(error)
        }
    }
}
