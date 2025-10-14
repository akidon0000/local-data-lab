//
//  IndexBar.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/14.
//

import SwiftUI

struct IndexBar: View {
    let keys: [String]
    @Binding var currentKey: String?
    var onSelect: (String) -> Void
    @State private var contentHeight: CGFloat = 1
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(keys, id: \.self) { key in
                Text(key)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 14)
            }
        }
        .padding(.vertical, 6)
        .frame(width: 28)
        .background(.ultraThinMaterial, in: Capsule())
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { contentHeight = max(1, proxy.size.height) }
                    .onChange(of: proxy.size.height) { newValue in
                        contentHeight = max(1, newValue)
                    }
            }
        )
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard !keys.isEmpty else { return }
                    let locationY = max(0, min(contentHeight, value.location.y))
                    let idxFloat = (locationY / contentHeight) * CGFloat(max(1, keys.count))
                    let index = Int(idxFloat)
                    let clamped = max(0, min(keys.count - 1, index))
                    let key = keys[clamped]
                    if currentKey != key {
                        currentKey = key
                        onSelect(key)
                    }
                }
                .onEnded { value in
                    guard !keys.isEmpty else { return }
                    let locationY = max(0, min(contentHeight, value.location.y))
                    let idxFloat = (locationY / contentHeight) * CGFloat(max(1, keys.count))
                    let index = Int(idxFloat)
                    let clamped = max(0, min(keys.count - 1, index))
                    let key = keys[clamped]
                    if currentKey != key {
                        currentKey = key
                    }
                    onSelect(key)
                }
        )
    }
}

