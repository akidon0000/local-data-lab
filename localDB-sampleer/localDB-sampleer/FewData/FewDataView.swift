//
//  FewDataView.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/15.
//

import SwiftUI
import SwiftData

struct FewDataView: View {
    @Environment(\.modelContext) var modelContext  
    @Query(sort: \Customers.name, order: .forward) var customerCards: [Customers]
  
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    ForEach(customerCards, id: \.name) { card in
                        Text("\(card.name)")
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
                            Button("1,000件追加") { generateData(count: 1000) }
                            Button("10,000件追加") { generateData(count: 10000) }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
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

