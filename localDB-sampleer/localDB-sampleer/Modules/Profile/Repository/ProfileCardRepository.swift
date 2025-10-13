//
//  ProfileCardRepository.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/11.
//

import SwiftData
import Foundation

@ModelActor
actor ProfileCardRepository {
    private(set) static var shared: ProfileCardRepository!
    
    static func createSharedInstance(modelContext: ModelContext) {
        shared = ProfileCardRepository(modelContainer: modelContext.container)
    }
    
    public func fetch(offset: Int = 0, limit: Int = 50, upper: String? = nil, lower: String? = nil) -> [ProfileCard] {
        
        var descriptor = FetchDescriptor<ProfileCard>(
            sortBy: [SortDescriptor(\ProfileCard.name, order: .forward)]
        )
        descriptor.fetchOffset = offset // 先頭から {offset} 件をスキップ
        descriptor.fetchLimit = limit // 最大 {limit} 件まで取得
        if let upper = upper, let lower = lower{
            descriptor.predicate = #Predicate<ProfileCard> { card in
                card.name < upper && card.name >= lower
            }
        }else if let lower = lower {
            // name が bound 以上のデータを取得する
            descriptor.predicate = #Predicate<ProfileCard> { $0.name >= lower }
        }
        let lists = try? modelContext.fetch(descriptor)
        return lists ?? []
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
    
//    private static func makeHiraganaName(_ index: Int) -> String {
//        let chars: [Character] = Array("あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん")
//        let length = 3 + (index % 3)
//        var result = String()
//        var seed = index
//        for i in 0..<length {
//            let pos = (seed + i * 7) % chars.count
//            result.append(chars[pos])
//        }
//        return result
//    }
//    
//    static func generateData(modelContext: ModelContext, count: Int = 1) {
//        for i in 1...count {
//            let instance = ProfileCard(name: Self.makeHiraganaName(i))
//            modelContext.insert(instance)
//        }
//        
//        do {
//            try modelContext.save()
//        } catch {
//            print("データの保存に失敗しました: \(error)")
//        }
//    }
//    
//    static func deleteAllData(modelContext: ModelContext) {
//        do {
//            try modelContext.delete(model: ProfileCard.self)
//        } catch {
//            print("データの削除に失敗しました: \(error)")
//        }
//    }
}
