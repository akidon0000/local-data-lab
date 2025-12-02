//
//  ToastModifier.swift
//  LocalDataLab
//
//  Created by Akihiro Matsuyama on 2025/12/02.
//

import SwiftUI

// MARK: - Toast Modifier
struct ToastModifier: ViewModifier {
    @Binding var message: String?
    let title: String
    let duration: TimeInterval

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message = message {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.8))
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            self.message = nil
                        }
                    }
                }
            }
            .animation(.spring(), value: message)
    }
}

extension View {
    func toast(message: Binding<String?>, title: String = "通知", duration: TimeInterval = 3) -> some View {
        modifier(ToastModifier(message: message, title: title, duration: duration))
    }
}
