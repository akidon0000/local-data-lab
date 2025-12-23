//
//  HiraganaGenerator.swift
//  LocalDataLab
//
//  Created by Akihiro Matsuyama on 2025/12/24.
//

import Foundation

enum HiraganaGenerator {
    private static let hiraganaCharacters: [Character] = Array("あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん")

    static func makeRandomName(length: Int) -> String {
        var result = String()
        result.reserveCapacity(length)
        for _ in 0..<length {
            let index = Int.random(in: 0..<hiraganaCharacters.count)
            result.append(hiraganaCharacters[index])
        }
        return result
    }
}
