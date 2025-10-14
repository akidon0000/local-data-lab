//
//  CustomersCardRow.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/11.
//

import SwiftUI

struct CustomersCardRow: View {
    let card: Customers
    let onDelete: ((Customers) -> Void)?
    
    init(card: Customers, onDelete: ((Customers) -> Void)? = nil) {
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
        CustomersCardRow(card: Customers(
            name: "田中 太郎"
        ))
        
        CustomersCardRow(card: Customers(
            name: "佐藤 花子"
        ))
    }
}
