////
////  BusinessCardRepository.swift
////  localDB-sampleer
////
////  Created by Akihiro Matsuyama on 2025/10/11.
////
//
//import Foundation
//import SwiftData
//
//@ModelActor
//actor BusinessCardRepository {
//    
//    /// バックグラウンドで総名刺数を取得
//    func getTotalCardsCount() async throws -> Int {
//        let descriptor = FetchDescriptor<BusinessCard>()
//        let cards = try modelContext.fetch(descriptor)
//        return cards.count
//    }
//    
//    /// バックグラウンドで名刺を取得
//    func getBusinessCards() async throws -> [BusinessCard] {
//        let descriptor = FetchDescriptor<BusinessCard>(
//            sortBy: [SortDescriptor(\.name, order: .reverse)]
//        )
//        return try modelContext.fetch(descriptor)
//    }
//
//    /// 新しいcontentを永続化する処理
//    func insertContent(contentEntity: ContentEntity) async {
//        let model = ContentModel(
//            id: contentEntity.id,
//            title: contentEntity.title
//        )
//        modelContext.insert(model)
//
//        guard modelContext.hasChanges else { return }
//        try? modelContext.save()
//
//        // 追加
//        NotificationCenter.default.post(
//            name: Notification.Name("shouldUpdateContents"),
//            object: nil
//        )
//    }
//}
