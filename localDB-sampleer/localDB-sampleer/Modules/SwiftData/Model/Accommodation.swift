//
//  Accommodation.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/09/25.
//

import Foundation
import SwiftData

@Model
class Accommodation {
    var name: String
    var address: String
    var checkInDate: Date
    var checkOutDate: Date
    
    init(name: String, address: String, checkInDate: Date, checkOutDate: Date) {
        self.name = name
        self.address = address
        self.checkInDate = checkInDate
        self.checkOutDate = checkOutDate
    }
}
