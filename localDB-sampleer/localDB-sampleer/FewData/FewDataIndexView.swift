//
//  FewDataIndexView.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/15.
//

import SwiftUI
import SwiftData
import Dispatch

struct FewDataIndexView: View {
    @Environment(\.modelContext) var modelContext  
    @State private var customerCards: [Customers] = []
    @State private var sections: [IndexedSection<Customers, String>] = []
    @State private var fetchMs: Double? = nil
    @State private var sectionMs: Double? = nil
    @State private var paintMs: Double? = nil
    @State private var uiStartTime: DispatchTime? = nil
    @State private var isLoading = false
  
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    ForEach(sections, id: \.key) { section in
                        Section {
                            ForEach(section.items, id: \.id) { card in
                                CustomersCardRow(card: card)
                                    .onAppear {
                                        if paintMs == nil, let start = uiStartTime {
                                            let now = DispatchTime.now()
                                            let ms = Double(now.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
                                            paintMs = ms
                                        }
                                    }
                            }
                        } header: {
                            Text(section.key)
                        }
                        .sectionIndexLabel(section.key)
                    }
                }
                if fetchMs != nil || sectionMs != nil || paintMs != nil || isLoading {
                    VStack(alignment: .trailing, spacing: 4) {
                        if isLoading { Text("Loading...").font(.caption).foregroundStyle(.secondary) }
                        if let f = fetchMs { Text(String(format: "fetch: %.1f ms", f)).font(.caption2) }
                        if let s = sectionMs { Text(String(format: "section/sort: %.1f ms", s)).font(.caption2) }
                        if let p = paintMs { Text(String(format: "first paint: %.1f ms", p)).font(.caption2) }
                        // メモリ推定（配列の参照ポインタ領域）
                        Text("arr: \(formatBytes(arrayPtrBytes))").font(.caption2)
                        Text("sec items: \(formatBytes(sectionItemsPtrBytes))").font(.caption2)
                        Text("total ptrs: \(formatBytes(arrayPtrBytes + sectionItemsPtrBytes))").font(.caption2)
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
                            Button("500,000件追加") { generateData(count: 500000) }
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
            }
            .onAppear { if customerCards.isEmpty { reload() } }
        }
    }
    
    private var sortedSectionKeys: [String] {
        ["あ","か","さ","た","な","は","ま","や","ら","わ"]
    }
    
    private func gojuonRow(for firstChar: Character) -> String {
        switch firstChar {
        case "あ","い","う","え","お": return "あ"
        case "か","き","く","け","こ": return "か"
        case "さ","し","す","せ","そ": return "さ"
        case "た","ち","つ","て","と": return "た"
        case "な","に","ぬ","ね","の": return "な"
        case "は","ひ","ふ","へ","ほ": return "は"
        case "ま","み","む","め","も": return "ま"
        case "や","ゆ","よ": return "や"
        case "ら","り","る","れ","ろ": return "ら"
        case "わ","を","ん": return "わ"
        default: return "#"
        }
    }
    
    private func buildSections(from items: [Customers]) -> [IndexedSection<Customers, String>] {
        var dict: [String: [Customers]] = [:]
        for item in items {
            let key: String = {
                guard let first = item.name.first else { return "#" }
                return gojuonRow(for: first)
            }()
            dict[key, default: []].append(item)
        }
        // キーの表示順に並べ替え
        var result: [IndexedSection<Customers, String>] = []
        for key in sortedSectionKeys {
            if var arr = dict[key] {
                arr.sort { $0.name < $1.name }
                result.append(IndexedSection<Customers, String>(key: key, items: arr))
            }
        }
        // 想定外キーがあれば末尾に
        for (key, arr) in dict where !sortedSectionKeys.contains(key) {
            let sorted = arr.sorted { $0.name < $1.name }
            result.append(IndexedSection<Customers, String>(key: key, items: sorted))
        }
        return result
    }

    // 推定: 配列が保持する参照ポインタの領域（要素数 × ポインタサイズ）
    private var arrayPtrBytes: Int {
        customerCards.count * MemoryLayout<Customers>.stride
    }
    private var sectionItemsPtrBytes: Int {
        sections.reduce(0) { $0 + $1.items.count * MemoryLayout<Customers>.stride }
    }
    private func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        let kb = Double(bytes) / 1024
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        let mb = kb / 1024
        return String(format: "%.2f MB", mb)
    }

    private func reload() {
        guard !isLoading else { return }
        isLoading = true
        fetchMs = nil
        sectionMs = nil
        paintMs = nil
        uiStartTime = nil
        
        Task {
            // fetch
            let fetchStart = DispatchTime.now()
            var descriptor = FetchDescriptor<Customers>(
                sortBy: [SortDescriptor(\Customers.name, order: .forward)]
            )
            descriptor.includePendingChanges = true
            let fetched = (try? modelContext.fetch(descriptor)) ?? []
            let fetchEnd = DispatchTime.now()
            let fetchDurationMs = Double(fetchEnd.uptimeNanoseconds - fetchStart.uptimeNanoseconds) / 1_000_000
            
            // section build
            let sectionStart = DispatchTime.now()
            let built = buildSections(from: fetched)
            let sectionEnd = DispatchTime.now()
            let sectionDurationMs = Double(sectionEnd.uptimeNanoseconds - sectionStart.uptimeNanoseconds) / 1_000_000
            
            await MainActor.run {
                customerCards = fetched
                sections = built
                fetchMs = fetchDurationMs
                sectionMs = sectionDurationMs
                uiStartTime = DispatchTime.now()
                isLoading = false
            }
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
}

