//
//  FewDataView.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/15.
//

import SwiftUI
import SwiftData
import Dispatch

struct FewDataView: View {
    @Environment(\.modelContext) var modelContext  
    @State private var customerCards: [Customers] = []
    @State private var fetchMs: Double? = nil
    @State private var sortMs: Double? = nil
    @State private var paintMs: Double? = nil
    @State private var uiStartTime: DispatchTime? = nil
    @State private var isLoading = false
  
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    ForEach(customerCards, id: \.name) { card in
                        Text(card.name)
                            .onAppear {
                                if paintMs == nil, let start = uiStartTime {
                                    let now = DispatchTime.now()
                                    let ms = Double(now.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
                                    paintMs = ms
                                }
                            }
                    }
                }
                if fetchMs != nil || sortMs != nil || paintMs != nil || isLoading {
                    VStack(alignment: .trailing, spacing: 4) {
                        if isLoading { Text("Loading...").font(.caption).foregroundStyle(.secondary) }
                        if let f = fetchMs { Text(String(format: "fetch: %.1f ms", f)).font(.caption2) }
                        if let s = sortMs { Text(String(format: "sort: %.1f ms", s)).font(.caption2) }
                        if let p = paintMs { Text(String(format: "first paint: %.1f ms", p)).font(.caption2) }
                        Text("arr: \(formatBytes(arrayPtrBytes))").font(.caption2)
                    }
                    .padding(8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding([.top, .trailing], 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
            .navigationTitle("\(customerCards.count)件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
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
                        Button { reload() } label: { Image(systemName: "arrow.clockwise") }
                    }
                }
            }
            .onAppear { if customerCards.isEmpty { reload() } }
        }
    }
    
    func deleteAllData() {
        do {
            try modelContext.delete(model: Customers.self)
            reload()
        } catch {
            print(error)
        }
    }
    
    func generateData(count: Int) {
        Task {
            var items = [Customers]()
            for _ in 1...count {
                let nameSize = Int.random(in: 1...10)
                let randomName = makeHiraganaName(nameSize)
                let customer = Customers(name: randomName)
                items.append(customer)
            }
            
            _ = items.map { modelContext.insert($0) }
            try? modelContext.save()
            await MainActor.run { reload() }
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

    private func reload() {
        guard !isLoading else { return }
        isLoading = true
        fetchMs = nil
        sortMs = nil
        paintMs = nil
        uiStartTime = nil
        Task {
            let fetchStart = DispatchTime.now()
            var descriptor = FetchDescriptor<Customers>(sortBy: [SortDescriptor(\Customers.name, order: .forward)])
            descriptor.predicate = #Predicate<Customers> { $0.name.starts(with: "ま")}
            descriptor.includePendingChanges = true
            let fetched = (try? modelContext.fetch(descriptor)) ?? []
            let fetchEnd = DispatchTime.now()
            let fms = Double(fetchEnd.uptimeNanoseconds - fetchStart.uptimeNanoseconds) / 1_000_000

            await MainActor.run {
                customerCards = fetched
                fetchMs = fms
                sortMs = 0
                uiStartTime = DispatchTime.now()
                isLoading = false
            }
        }
    }

    private var arrayPtrBytes: Int {
        customerCards.count * MemoryLayout<Customers>.stride
    }
    private func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        let kb = Double(bytes) / 1024
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        let mb = kb / 1024
        return String(format: "%.2f MB", mb)
    }
}

