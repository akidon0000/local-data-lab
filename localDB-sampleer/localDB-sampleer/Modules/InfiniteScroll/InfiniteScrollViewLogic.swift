//
//  InfiniteScrollViewLogic.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/11.
//

import SwiftData
import SwiftUI

extension InfiniteScrollView {
    // MARK: - データ管理メソッド
    
    // 名刺を追加
    func addBusinessCard(
        name: String,
        company: String,
        position: String
    ) {
        guard !name.isEmpty && !company.isEmpty else { return }
        
        let newCard = BusinessCard(
            name: name,
            company: company,
            position: position
        )
        
        modelContext.insert(newCard)
        
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "名刺の保存に失敗しました: \(error.localizedDescription)"
        }
    }
    
    // 名刺を削除
    func deleteBusinessCard(_ card: BusinessCard) {
        modelContext.delete(card)
        
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "名刺の削除に失敗しました: \(error.localizedDescription)"
        }
    }
    
    // サンプルデータを生成
    func generateSampleData() {
        let sampleCards = [
            ("田中 太郎", "株式会社サンプル", "営業部長"),
            ("佐藤 花子", "テクノロジー株式会社", "エンジニア"),
            ("鈴木 一郎", "デザイン事務所", "デザイナー"),
            ("高橋 美咲", "マーケティング会社", "マネージャー"),
            ("山田 健太", "コンサルティング会社", "コンサルタント")
        ]
        
        for (name, company, position) in sampleCards {
            // 重複チェック
            let descriptor = FetchDescriptor<BusinessCard>(
                predicate: #Predicate { card in
                    card.name == name && card.company == company
                }
            )
            
            do {
                let existingCards = try modelContext.fetch(descriptor)
                if existingCards.isEmpty {
                    addBusinessCard(
                        name: name,
                        company: company,
                        position: position
                    )
                }
            } catch {
                print("サンプルデータの重複チェックに失敗: \(error)")
            }
        }
    }
    
    // 大量のサンプルデータを生成（無限スクロールのテスト用）
    func generateLargeSampleData() {
        let companies = ["株式会社A", "株式会社B", "株式会社C", "株式会社D", "株式会社E"]
        let positions = ["営業", "エンジニア", "デザイナー", "マネージャー", "ディレクター"]
        let firstNames = ["太郎", "花子", "一郎", "美咲", "健太", "由美", "大輔", "恵子", "翔太", "麻衣"]
        let lastNames = ["田中", "佐藤", "鈴木", "高橋", "山田", "渡辺", "伊藤", "中村", "小林", "加藤"]
        
        for _ in 1...100 {
            let lastName = lastNames.randomElement()!
            let firstName = firstNames.randomElement()!
            let company = companies.randomElement()!
            let position = positions.randomElement()!
            
            addBusinessCard(
                name: "\(lastName) \(firstName)",
                company: company,
                position: position
            )
        }
    }
}
