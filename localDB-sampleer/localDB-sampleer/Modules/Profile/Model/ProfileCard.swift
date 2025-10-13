//
//  ProfileCard.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/11.
//

import Foundation
import SwiftData

@Model class ProfileCard {
    var name: String
    var createdAt: Date
    
    init(name: String, createdAt: Date = Date()) {
        self.name = name
        self.createdAt = createdAt
    }
    
    static func predicate(name: String) -> Predicate<ProfileCard> {
        return #Predicate<ProfileCard> { card in
            if name == "" {
                return true
            } else {
                return card.name.contains(name)
            }
        }
    }
}
