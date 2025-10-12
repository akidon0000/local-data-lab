//
//  ProfileCard.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/11.
//

import Foundation
import SwiftData

@Model class ProfileCard {
    var name: String
    var createdAt: Date
    
    init(name: String, createdAt: Date = Date()) {
        self.name = name
        self.createdAt = createdAt
    }
    
    static func predicate(
        name: String
    ) -> Predicate<ProfileCard> {  // 以下省略
        
        return #Predicate<ProfileCard> { profileCard in
            profileCard.name == name
        }
        
    }
    
    static func generateData(modelContext: ModelContext, count: Int = 1) {
        for i in 1...count {
            let instance = ProfileCard(name: "User \(i)")
            modelContext.insert(instance)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("データの保存に失敗しました: \(error)")
        }
    }
    
    static func deleteAllData(modelContext: ModelContext) {
        do {
            // 全てのProfileCardを取得
            let fetchDescriptor = FetchDescriptor<ProfileCard>()
            let allCards = try modelContext.fetch(fetchDescriptor)
            
            // 全てのカードを削除
            for card in allCards {
                modelContext.delete(card)
            }
            
            // 変更を保存
            try modelContext.save()
            print("全ての名刺データを削除しました（\(allCards.count)件）")
        } catch {
            print("データの削除に失敗しました: \(error)")
        }
    }
}

//extension ProfileCard {
//    static let container = try! ModelContainer(for: ProfileCard.self)
//}
