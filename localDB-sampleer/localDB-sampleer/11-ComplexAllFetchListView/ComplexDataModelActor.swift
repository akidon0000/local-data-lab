//
//  ComplexDataModelActor.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/17.
//

import Foundation
import SwiftData

@ModelActor
actor ComplexDataModelActor {

    func fetchAllComplexIndexSchools() throws -> [ComplexIndexSchool] {
        var descriptor = FetchDescriptor<ComplexIndexSchool>(
            sortBy: [SortDescriptor(\ComplexIndexSchool.name, order: .forward)]
        )
        descriptor.includePendingChanges = true
        return try modelContext.fetch(descriptor)
    }

    func fetchPreviewComplexIndexSchools(limit: Int = 1000) throws -> [ComplexIndexSchool] {
        var descriptor = FetchDescriptor<ComplexIndexSchool>(
            sortBy: [SortDescriptor(\ComplexIndexSchool.name, order: .forward)]
        )
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = 0
        descriptor.includePendingChanges = true
        return try modelContext.fetch(descriptor)
    }

    // 非Sendableを跨がないため、IDのみを返すAPI
    func fetchAllComplexIndexSchoolIdsSortedByName() throws -> [String] {
        var descriptor = FetchDescriptor<ComplexIndexSchool>(
            sortBy: [SortDescriptor(\ComplexIndexSchool.name, order: .forward)]
        )
        descriptor.includePendingChanges = true
        let items = try modelContext.fetch(descriptor)
        return items.map { $0.id }
    }
}
