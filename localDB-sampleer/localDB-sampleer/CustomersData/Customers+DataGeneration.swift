//
//  Customers+DataGeneration.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/13.
//

import Foundation
import SwiftData

extension Customers {
    static func generateData(count: Int) {
        Task {
            var items = [Customers]()
            for i in 1...count {
                let nameSize = Int.random(in: 1...10)
                let randomName = makeHiraganaName(nameSize)
                let customer = Customers(name: randomName)
                items.append(customer)
            }
            
//            do {
//                try await CustomersActor.shared.insert(items: items)
//            } catch {
//                print("データの生成に失敗しました: \(error.localizedDescription)")
//            }
        }
        
        // ランダムな名前を生成する関数（ひらがな）
        func makeHiraganaName(_ length: Int) -> String {
            let chars: [Character] = Array("あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん")
            var result = String()
            for i in 0..<length {
                // 45音 + ん = 46文字
                let pos = Int.random(in: 0..<46)
                result.append(chars[pos])
            }
            return result
        }
    }
}
