//
//  SimpleDescriptorObject.swift
//  LocalDataLab
//
//  Created by Akihiro Matsuyama on 2025/12/03.
//

import Foundation
import SwiftData

@Model
class SimpleDescriptorObject {
    @Attribute(.unique) var id: String
    #Index<SimpleDescriptorObject>([\.name])
    var name: String

    init(name: String = "") {
        self.id = UUID().uuidString
        self.name = name
    }
}
