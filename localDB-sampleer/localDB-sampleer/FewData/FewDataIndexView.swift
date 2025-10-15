//
//  FewDataIndexView.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/15.
//

import SwiftUI
import SwiftData

struct FewDataIndexView: View {
    @Environment(\.modelContext) var modelContext  
    @Query(sort: \Customers.name, order: .forward) var customerCards: [Customers]
  
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    ForEach(customerCardSections, id: \.key) { section in
                        Section {
                            ForEach(section.items, id: \.id) { card in
                                CustomersCardRow(card: card)
                            }
                        } header: {
                            Text(section.key)
                        }
                        .sectionIndexLabel(section.key)
                    }
                }
            }
            .navigationTitle("名刺一覧 読み込み: (\(customerCards.count))件")
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
                    }
                }
            }
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
    
    private var customerCardSections: [IndexedSection<Customers, String>] {
        var dict: [String: [Customers]] = [:]
        for item in customerCards {
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
    
    func deleteAllData() {
        do {
            try modelContext.delete(model: Customers.self)
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

