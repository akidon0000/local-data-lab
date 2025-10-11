//
//  BusinessCard.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/11.
//

import Foundation
import SwiftData

@Model
class BusinessCard {
    var name: String
    var company: String
    var position: String
    var createdAt: Date
    var updatedAt: Date
    
    init(
        name: String,
        company: String,
        position: String
    ) {
        self.name = name
        self.company = company
        self.position = position
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func updateTimestamp() {
        self.updatedAt = Date()
    }
}
