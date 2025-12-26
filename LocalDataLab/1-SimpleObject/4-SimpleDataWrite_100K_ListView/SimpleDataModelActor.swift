//
//  SimpleDataModelActor.swift
//  LocalDataLab
//
//  Created by Akihiro Matsuyama on 2025/10/16.
//

import Foundation
import SwiftData

@ModelActor
actor SimpleDataModelActor {
    
    func fetchAllData() throws -> [SimpleData_100K] {
        let descriptor = FetchDescriptor<SimpleData_100K>(
            sortBy: [SortDescriptor(\SimpleData_100K.name, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func insert(items: [SimpleData_100K]) throws -> (insertMs: Double, saveMs: Double, totalMs: Double) {
        let t0 = DispatchTime.now()
        _ = items.map { modelContext.insert($0) }
        let t1 = DispatchTime.now()
        try modelContext.save()
        let t2 = DispatchTime.now()
        let insertMs = Double(t1.uptimeNanoseconds - t0.uptimeNanoseconds) / 1_000_000
        let saveMs = Double(t2.uptimeNanoseconds - t1.uptimeNanoseconds) / 1_000_000
        let totalMs = Double(t2.uptimeNanoseconds - t0.uptimeNanoseconds) / 1_000_000
        return (insertMs, saveMs, totalMs)
    }
    
    func deleteAll() throws {
        try modelContext.delete(model: SimpleData_100K.self)
    }
}
