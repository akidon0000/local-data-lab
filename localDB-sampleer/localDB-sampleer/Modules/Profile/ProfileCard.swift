//
//  ProfileCard.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/11.
//

import Foundation
import SwiftData

@Model
class ProfileCard {
    var name: String
    var createdAt: Date
    
    init(
        name: String
    ) {
        self.name = name
        self.createdAt = Date()
    }
}
