//
//  ProfileCardRepository.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/11.
//

import SwiftData

@ModelActor
actor ProfileCardRepository {
    private(set) static var shared: ProfileCardRepository!
    
    static func createSharedInstance(modelContext: ModelContext) {
        shared = ProfileCardRepository(modelContainer: modelContext.container)
    }
    
    public func getAll() -> [ProfileCard]? {
        try? modelContext.fetch(FetchDescriptor<ProfileCard>())
    }
    
    public func create<T: PersistentModel>(todo: [T]) throws {
        _ = todo.map { modelContext.insert($0) }
        try? modelContext.save()
    }
    
    
    public func deleteAll() throws {
        try modelContext.delete(model: ProfileCard.self)
    }
}
