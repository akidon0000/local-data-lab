//
//  ItemViewModel.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/09/25.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
class ItemViewModel {
    private var modelContext: ModelContext
    var items: [Item] = []
    var errorMessage: String?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchItems()
    }
    
    func fetchItems() {
        do {
            let descriptor = FetchDescriptor<Item>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            items = try modelContext.fetch(descriptor)
            errorMessage = nil
        } catch {
            errorMessage = "アイテムの取得に失敗しました: \(error.localizedDescription)"
            print(errorMessage ?? "")
        }
    }
    
    func addItem(name: String) {
        guard !name.isEmpty else { return }
        
        let newItem = Item(name: name)
        modelContext.insert(newItem)
        
        do {
            try modelContext.save()
            fetchItems()
            errorMessage = nil
        } catch {
            errorMessage = "アイテムの保存に失敗しました: \(error.localizedDescription)"
            print(errorMessage ?? "")
        }
    }
    
    func deleteItem(_ item: Item) {
        modelContext.delete(item)
        
        do {
            try modelContext.save()
            fetchItems()
            errorMessage = nil
        } catch {
            errorMessage = "アイテムの削除に失敗しました: \(error.localizedDescription)"
            print(errorMessage ?? "")
        }
    }
    
    func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            modelContext.delete(item)
        }
        
        do {
            try modelContext.save()
            fetchItems()
            errorMessage = nil
        } catch {
            errorMessage = "アイテムの削除に失敗しました: \(error.localizedDescription)"
            print(errorMessage ?? "")
        }
    }
}
