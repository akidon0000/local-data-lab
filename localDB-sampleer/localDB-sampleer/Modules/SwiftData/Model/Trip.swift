//
//  Trip.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/09/25.
//

import Foundation
import SwiftData

@Model
class Trip {
    var name: String
    var destination: String
    var startDate: Date
    var endDate: Date
    var accommodation: Accommodation?
    
    init(name: String, destination: String, startDate: Date, endDate: Date, accommodation: Accommodation? = nil) {
        self.name = name
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
        self.accommodation = accommodation
    }
}
