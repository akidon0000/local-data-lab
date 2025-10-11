//
//  DatabaseOptionCard.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/09/25.
//

import SwiftUI

struct DatabaseOptionCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isAvailable: Bool
    
    init(title: String, description: String, icon: String, color: Color, isAvailable: Bool = true) {
        self.title = title
        self.description = description
        self.icon = icon
        self.color = color
        self.isAvailable = isAvailable
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            if isAvailable {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .opacity(isAvailable ? 1.0 : 0.5)
        .overlay(
            !isAvailable ? preparingBadge : nil
        )
    }
    
    private var preparingBadge: some View {
        Text("準備中")
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.gray)
            .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 16) {
        DatabaseOptionCard(
            title: "SwiftData",
            description: "Appleの最新データ永続化フレームワーク",
            icon: "cylinder.fill",
            color: .blue,
            isAvailable: true
        )
        
        DatabaseOptionCard(
            title: "Core Data",
            description: "従来のAppleデータ永続化フレームワーク",
            icon: "externaldrive.fill",
            color: .orange,
            isAvailable: false
        )
    }
    .padding()
}
