//
//  SimpleIndexObject.swift
//  LocalDataLab
//
//  Created by Akihiro Matsuyama on 2025/12/03.
//

import Foundation
import SwiftData

@Model
class SimpleIndexObject {
    @Attribute(.unique) var id: String
    var name: String

    init(name: String = "") {
        self.id = UUID().uuidString
        self.name = name
    }
}
