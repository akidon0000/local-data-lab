//
//  ComplexDataIndexView.swift
//  LocalDataLab
//
//  Created by Akihiro Matsuyama on 2025/10/16.
//

import Dispatch
import SwiftData
import SwiftUI

struct ComplexDataIndexView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var schools: [ComplexIndexSchool] = []
    @State private var isLoading = false
    @State private var searchText: String = ""
    
    // デバッグ用
    @State private var fetchMs: Double? = nil
    
    var searchResults: [ComplexIndexSchool] {
           if searchText.isEmpty {
               return schools
           } else {
               return schools.filter { $0.name.contains(searchText) }
           }
       }
    
    var body: some View {
        List {
            ForEach(searchResults, id: \.id) { school in
                VStack(alignment: .leading, spacing: 4) {
                    Text(school.name)
                        .font(.headline)
                    HStack(spacing: 8) {
                        Text(school.location)
                        Text(String(describing: school.type))
                        Text("students: \(school.students.count)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .onDelete(perform: delete)
        }
        .searchable(text: $searchText)
        .overlay(alignment: .topTrailing) { PerformanceView() }
        .overlay(alignment: .center) {
            if schools.isEmpty && !isLoading {
                VStack(spacing: 12) {
                    Text("データがありません")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Button("10件追加") { generateData(count: 10) }
                        .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .navigationTitle("\(schools.count)件")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) { ToolBarView() }
        }
        .onAppear { if schools.isEmpty { reload() } }
    }
    
    @ViewBuilder
    private func PerformanceView() -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            if isLoading {
                HStack(spacing: 6) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.small)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if let f = fetchMs {
                Text(String(format: "fetch: %.1f ms", f))
                    .font(.caption2)
            }
        }
        .background(.ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: 8,
                                         style: .continuous))
        .padding(8)
    }
    
    @ViewBuilder
    private func ToolBarView() -> some View {
        HStack {
            Menu {
                Button("全て削除", role: .destructive) {
                    deleteAllData()
                }
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            
            Menu {
                Button("10件追加") { generateData(count: 10) }
                Button("100件追加") { generateData(count: 100) }
                Button("1,000件追加") { generateData(count: 1000) }
                Button("100,000件追加") { generateData(count: 100000) }
            } label: {
                Image(systemName: "plus")
            }
        }
    }
    
    private func deleteAllData() {
        do {
            try modelContext.delete(model: ComplexIndexSchool.self)
            reload()
        } catch {
            print(error)
        }
    }
    
    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let school = schools[index]
            modelContext.delete(school)
        }
        do {
            try modelContext.save()
            reload()
        } catch {
            print(error)
        }
    }
    
    private func generateData(count: Int) {
        Task {
            var created: [ComplexIndexSchool] = []
            for _ in 0..<count {
                if let school = try? ComplexIndexSchool() {
                    let studentCount = Int.random(in: 5..<21)
                    for _ in 0..<studentCount {
                        _ = try? ComplexIndexStudent(school: school)
                    }
                    created.append(school)
                }
            }
            _ = created.map { modelContext.insert($0) }
            do { try modelContext.save() } catch { print(error) }
            await MainActor.run { reload() }
        }
    }
    
    // フェッチ計測付きの再読込
    private func reload() {
        guard !isLoading else { return }
        isLoading = true
        fetchMs = nil
        Task {
            let fetchStart = DispatchTime.now()
            var descriptor = FetchDescriptor<ComplexIndexSchool>(
                sortBy: [SortDescriptor(\ComplexIndexSchool.name, order: .forward)]
            )
            descriptor.includePendingChanges = true
            let fetched = (try? modelContext.fetch(descriptor)) ?? []
            let fetchEnd = DispatchTime.now()
            let fetchDurationMs = Double(fetchEnd.uptimeNanoseconds - fetchStart.uptimeNanoseconds) / 1_000_000
            await MainActor.run {
                schools = fetched
                fetchMs = fetchDurationMs
                isLoading = false
            }
        }
    }
}


