//
//  SimpleObject.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/16.
//

import Foundation
import SwiftData

@Model 
class SimpleObject {
    #Index<SimpleObject>([\.name])
    @Attribute(.unique) var id: String
    var name: String
    
    init(name: String = "") {
        self.id = UUID().uuidString
        self.name = name
    }
}


