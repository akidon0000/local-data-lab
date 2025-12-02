//
//  SimpleDataWrite_100K_ListView.swift
//  LocalDataLab
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
    @State private var approxSizeBytes: Int = 0
    @State private var approxSizeFormatted: String = ""
    
    @State private var simpleDataModelActor: SimpleDataModelActor? = nil
    
    // 計測表示
    @State private var showMetricsAlert: Bool = false
    @State private var metricsText: String = ""
    
    init(simpleDataModelActor: SimpleDataModelActor? = nil) {
        self._simpleDataModelActor = State(initialValue: simpleDataModelActor)
    }
  
    var body: some View {
        ZStack {
            ProgressView()
        }
        .safeAreaInset(edge: .top) {
            HStack {
                if simpleDatas.isEmpty {
                    PaformanceView()
                }else{
                    Text("書き込み完了")
                }
            }
        }
        .navigationTitle("\(simpleDatas.count)件")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) { ToolBarView() }
        }
        .onAppear {
            if simpleDataModelActor == nil {
                simpleDataModelActor = SimpleDataModelActor(modelContainer: modelContext.container)
            }
            updateApproxSize()
        }
        .onChange(of: simpleDatas.count) { _ in
            updateApproxSize()
        }
        .alert("計測結果", isPresented: $showMetricsAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(metricsText)
        }
    }
    
    @ViewBuilder
    private func PaformanceView() -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            if isLoading && simpleDatas.isEmpty {
                HStack(spacing: 6) {
                    Text("Loading...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if let f = fetchMs {
                Text(String(format: "fetch: %.1f ms", f))
                    .font(.caption2)
            }
            if !approxSizeFormatted.isEmpty {
                Text("配列のバイト数: \(approxSizeBytes) B (\(approxSizeFormatted))")
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
        }
    }
    
    private func deleteAllData() {
        guard let actor = simpleDataModelActor else { return }
        Task.detached(priority: .background) {
            await MainActor.run { isLoading = true }
            do {
                try await actor.deleteAll()
            } catch {
                print(error)
            }
            await MainActor.run { isLoading = false }
        }
    }
    
    private func generateData(count: Int) {
        guard let actor = simpleDataModelActor else { return }
        Task.detached(priority: .background) {
            do {
                let t0 = DispatchTime.now()
                var items = [SimpleData_100K]()
                for _ in 0..<count {
                    let customer = SimpleData_100K(name: "akidon")
                    items.append(customer)
                }
                let t1 = DispatchTime.now()
                let createMs = Double(t1.uptimeNanoseconds - t0.uptimeNanoseconds) / 1_000_000
                
                let metrics = try await actor.insert(items: items)
                let message = String(
                    format: "生成: %.1fms\n挿入: %.1fms\n保存: %.1fms\n合計: %.1fms\n件数: %d",
                    createMs, metrics.insertMs, metrics.saveMs, (createMs + metrics.totalMs), count
                )
                print(message)
                await MainActor.run {
                    metricsText = message
                    showMetricsAlert = true
                    isLoading = true
                }
                await MainActor.run { updateApproxSize() }
            } catch {
                print(error)
            }
        }
    }

    private func updateApproxSize() {
        // 配列自体の要素参照分（ランタイム依存・概算）。
        // Swift のクラス配列は各要素が参照（ポインタ）を持つため、要素数分の参照サイズを足して概算。
        let pointerBytesPerElement = MemoryLayout<UnsafeRawPointer>.size
        var totalBytes = simpleDatas.count * pointerBytesPerElement
        for d in simpleDatas {
            let idBytes = d.id.utf8.count
            let nameBytes = d.name.utf8.count
            let dateBytes = 8
            let overhead = 64
            totalBytes += idBytes + nameBytes + dateBytes + overhead
        }
        approxSizeBytes = totalBytes
        approxSizeFormatted = byteCountFormatter(bytes: totalBytes)
    }

    private func byteCountFormatter(bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
