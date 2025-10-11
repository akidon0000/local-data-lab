//
//  SwiftDataView.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/09/25.
//

import SwiftData
import SwiftUI

struct SwiftDataView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TripViewModel?
    @State private var newTripName = ""
    @State private var newDestination = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400) // 翌日
    
    var body: some View {
        VStack {
            // 旅行追加フォーム
            VStack(spacing: 12) {
                TextField("旅行名を入力", text: $newTripName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("目的地を入力", text: $newDestination)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                DatePicker("開始日", selection: $startDate, displayedComponents: .date)
                DatePicker("終了日", selection: $endDate, displayedComponents: .date)
                
                Button("旅行を追加") {
                    addTrip()
                }
//                .disabled(newTripName.isEmpty || newDestination.isEmpty)
                .padding(.vertical, 8)
            }
            .padding()
            
            // エラーメッセージ表示
            if let errorMessage = viewModel?.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            // 旅行リスト
            if let trips = viewModel?.trips {
                List {
                    ForEach(trips) { trip in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(trip.name)
                                .font(.headline)
                            Text("目的地: \(trip.destination)")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Text("期間: \(trip.startDate, format: .dateTime.day().month()) - \(trip.endDate, format: .dateTime.day().month())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete(perform: deleteTrips)
                }
                
                if trips.isEmpty {
                    Text("旅行がありません")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
        }
        .navigationTitle("SwiftData - 旅行管理")
        .onAppear {
            if viewModel == nil {
                viewModel = TripViewModel(modelContext: modelContext)
            }
        }
    }
    
    private func addTrip() {
        newTripName = "Hoge"
        newDestination = "Fuga"
        guard !newTripName.isEmpty && !newDestination.isEmpty else { return }
        let trip = Trip(name: newTripName,
                        destination: newDestination,
                        startDate: startDate,
                        endDate: endDate)
        viewModel?.add(trip: trip)
        
        newTripName = ""
        newDestination = ""
        startDate = Date()
        endDate = Date().addingTimeInterval(86400)
    }
    
    private func deleteTrips(offsets: IndexSet) {
        viewModel?.deleteTrips(at: offsets)
    }
}

#Preview {
    NavigationView {
        SwiftDataView()
    }
    .modelContainer(for: Trip.self, inMemory: true)
}
