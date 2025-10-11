//
//  ProfileCardRow.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/11.
//

import SwiftUI

struct ProfileCardRow: View {
    let card: ProfileCard
    let onDelete: ((ProfileCard) -> Void)?
    
    init(card: ProfileCard, onDelete: ((ProfileCard) -> Void)? = nil) {
        self.card = card
        self.onDelete = onDelete
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.name)
                .font(.headline)
                .fontWeight(.semibold)
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
        ProfileCardRow(card: ProfileCard(
            name: "田中 太郎"
        ))
        
        ProfileCardRow(card: ProfileCard(
            name: "佐藤 花子"
        ))
    }
}
