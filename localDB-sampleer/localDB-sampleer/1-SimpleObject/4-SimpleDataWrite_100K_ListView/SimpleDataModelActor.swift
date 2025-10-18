//
//  SimpleDataModelActor.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/16.
//

import Foundation
import SwiftData

@ModelActor
actor SimpleDataModelActor {
    
    func fetchAllData() throws -> [SimpleData_100K] {
        var descriptor = FetchDescriptor<SimpleData_100K>(
            sortBy: [SortDescriptor(\SimpleData_100K.name, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func insert(items: [SimpleData_100K]) throws {
        _ = items.map { modelContext.insert($0) }
        try modelContext.save()
    }
    
    func deleteAll() throws {
        try modelContext.delete(model: SimpleData_100K.self)
    }
}
