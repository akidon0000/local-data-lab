//
//  SimpleObject.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/16.
//

import Foundation
import SwiftData

@Model class SimpleObject {
    @Attribute(.unique) var id: String
    var name: String
    var creationDate: Date
    
    init(name: String = "", createdAt: Date = .now) {
        self.id = UUID().uuidString
        self.name = name
        self.creationDate = createdAt
    }
}


