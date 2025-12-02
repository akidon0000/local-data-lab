//
//  SimpleObject_100K_2.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/18.
//

import Foundation
import SwiftData

@Model class SimpleData_100K_2 {
    @Attribute(.unique) var id: String
    var name: String
    var creationDate: Date
    
    init(name: String = "", createdAt: Date = .now) {
        self.id = UUID().uuidString
        self.name = name
        self.creationDate = createdAt
    }
}
