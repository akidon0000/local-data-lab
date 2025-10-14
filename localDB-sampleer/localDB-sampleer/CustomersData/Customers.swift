//
//  Customers.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/11.
//

import Foundation
import SwiftData

@Model class Customers {
    @Attribute(.unique) var id: String
    var creationDate: Date

    var name: String
    
    init(name: String = "", createdAt: Date = .now) {
        self.id = UUID().uuidString
        self.name = name
        self.creationDate = createdAt
    }
    
    static func predicate(name: String) -> Predicate<Customers> {
        return #Predicate<Customers> { card in
            if name == "" {
                return true
            } else {
                return card.name.contains(name)
            }
        }
    }
}
