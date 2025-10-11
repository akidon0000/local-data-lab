//
//  TripViewModel.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/09/25.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
class TripViewModel {
    private var modelContext: ModelContext
    var trips: [Trip] = []
    var errorMessage: String?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchTrips()
    }
    
    func fetchTrips() {
        do {
            let descriptor = FetchDescriptor<Trip>(
                sortBy: [SortDescriptor(\.startDate, order: .reverse)]
            )
            trips = try modelContext.fetch(descriptor)
            errorMessage = nil
        } catch {
            errorMessage = "旅行の取得に失敗しました: \(error.localizedDescription)"
            print(errorMessage ?? "")
        }
    }
    
    func add(trip: Trip) {
        modelContext.insert(trip)
        
        do {
            try modelContext.save()
            fetchTrips()
            errorMessage = nil
        } catch {
            errorMessage = "旅行の保存に失敗しました: \(error.localizedDescription)"
            print(errorMessage ?? "")
        }
    }
    
    func deleteTrip(_ trip: Trip) {
        modelContext.delete(trip)
        
        do {
            try modelContext.save()
            fetchTrips()
            errorMessage = nil
        } catch {
            errorMessage = "旅行の削除に失敗しました: \(error.localizedDescription)"
            print(errorMessage ?? "")
        }
    }
    
    func deleteTrips(at offsets: IndexSet) {
        for index in offsets {
            let trip = trips[index]
            modelContext.delete(trip)
        }
        
        do {
            try modelContext.save()
            fetchTrips()
            errorMessage = nil
        } catch {
            errorMessage = "旅行の削除に失敗しました: \(error.localizedDescription)"
            print(errorMessage ?? "")
        }
    }
}

