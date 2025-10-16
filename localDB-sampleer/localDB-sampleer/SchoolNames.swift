//
//  SchoolNames.swift
//  localDB-sampleer
//
//  Created by Assistant on 2025/10/16.
//

import Foundation

struct SchoolNames {
    static let schoolNames: [String] = {
        return (0..<300).map { _ in Self.makeHiraganaName(10) }
    }()

    private static func makeHiraganaName(_ length: Int) -> String {
        let chars: [Character] = Array("あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん")
        var result = String()
        result.reserveCapacity(length)
        for _ in 0..<length {
            let pos = Int.random(in: 0..<chars.count)
            result.append(chars[pos])
        }
        return result
    }
}


