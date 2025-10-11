//
//  BusinessCardRow.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/11.
//

import SwiftUI

struct BusinessCardRow: View {
    let card: BusinessCard
    let onDelete: ((BusinessCard) -> Void)?
    
    init(card: BusinessCard, onDelete: ((BusinessCard) -> Void)? = nil) {
        self.card = card
        self.onDelete = onDelete
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 名前と会社名
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(card.company)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 役職
                Text(card.position)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            if let onDelete = onDelete {
                Button("削除", role: .destructive) {
                    onDelete(card)
                }
            }
        }
    }
}

// プレビュー用のサンプルデータ
#Preview {
    List {
        BusinessCardRow(card: BusinessCard(
            name: "田中 太郎",
            company: "株式会社サンプル",
            position: "営業部長"
        ))
        
        BusinessCardRow(card: BusinessCard(
            name: "佐藤 花子",
            company: "テクノロジー株式会社",
            position: "エンジニア"
        ))
    }
}
