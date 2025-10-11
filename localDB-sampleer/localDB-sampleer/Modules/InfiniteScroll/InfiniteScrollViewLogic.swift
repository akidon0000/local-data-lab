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
        Task {
            do {
                try await BusinessCardManager.shared.addBusinessCard(
                    name: name,
                    company: company,
                    position: position,
                    to: modelContext
                )
                await MainActor.run {
                    errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = "名刺の保存に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // 名刺を削除
    func deleteBusinessCard(_ card: BusinessCard) {
        Task {
            do {
                try await BusinessCardManager.shared.deleteBusinessCard(
                    card,
                    from: modelContext
                )
                await MainActor.run {
                    errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = "名刺の削除に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // 全ての名刺を削除
    func deleteAllBusinessCards() {
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            do {
                try await BusinessCardManager.shared.deleteAllBusinessCards(from: modelContext)
                await MainActor.run {
                    isLoading = false
                    errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = "名刺の削除に失敗しました: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    // 指定件数の名刺を削除（最新から）
    func deleteBusinessCards(count: Int) {
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            do {
                try await BusinessCardManager.shared.deleteBusinessCards(
                    count: count,
                    from: modelContext
                )
                await MainActor.run {
                    isLoading = false
                    errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = "名刺の削除に失敗しました: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    // サンプルデータを生成
    func generateSampleData() {
        Task {
            do {
                try await BusinessCardManager.shared.generateSampleData(to: modelContext)
                await MainActor.run {
                    errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = "サンプルデータの生成に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // 指定件数の名刺を一括追加
    func addBusinessCards(count: Int) {
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            do {
                try await BusinessCardManager.shared.addBusinessCards(
                    count: count,
                    to: modelContext
                )
                await MainActor.run {
                    isLoading = false
                    errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = "名刺の保存に失敗しました: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    // 大量のサンプルデータを生成（無限スクロールのテスト用）
    func generateLargeSampleData() {
        addBusinessCards(count: 500)
    }
}
