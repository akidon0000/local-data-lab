//
//  ComplexPagingListView.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/16.
//
//
//  SimpleDataListView.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/15.
//

import SwiftData
import SwiftUI

struct ComplexPagingListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var schools = [ComplexIndexSchool]()
    @State private var isLoading = false
    // ページング用 最初から{{offset}}件スキップ、{{limit}}件取得
    @State private var offset: Int = 0
    @State private var limit: Int = 50
    
    // デバッグ用
    @State private var fetchMs: Double? = nil
  
    var body: some View {
        List {
            ForEach(Array(schools.enumerated()), id: \.element.id) { index, school in
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
                .onAppear {
                    if index >= schools.count - 1 {
                        buttomSentinelAppear()
                    }
                }
            }
        }
        .onAppear {
            loadInitial()
        }
        .overlay(alignment: .topTrailing) { PaformanceView() }
        .navigationTitle("\(schools.count)件")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) { ToolBarView() }
        }
    }
    
    @ViewBuilder
    private func PaformanceView() -> some View {
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
                Button("100件追加") { generateData(count: 100) }
                Button("1,000,000件追加") { generateData(count: 1000000) }
            } label: {
                Image(systemName: "plus")
            }
        }
    }
    
    private func loadInitial() {
        guard !isLoading else { return }
        isLoading = true
        Task {
            var descriptor = FetchDescriptor<ComplexIndexSchool>(
                sortBy: [SortDescriptor(\ComplexIndexSchool.name, order: .forward)]
            )
            descriptor.fetchLimit = limit
            descriptor.fetchOffset = offset
            let list = (try? modelContext.fetch(descriptor)) ?? []
            await MainActor.run {
                schools = list
                offset += list.count
                isLoading = false
            }
        }
    }
    
    private func buttomSentinelAppear() {
        guard !isLoading else { return }
        isLoading = true
        var descriptor = FetchDescriptor<ComplexIndexSchool>(
            sortBy: [SortDescriptor(\ComplexIndexSchool.name, order: .forward)]
        )
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        Task {
            let next = (try? modelContext.fetch(descriptor)) ?? []
            await MainActor.run {
                schools.append(contentsOf: next)
                offset += next.count
                isLoading = false
            }
        }
    }
    
    private func deleteAllData() {
        do {
            try modelContext.delete(model: SimpleData.self)
        } catch {
            print(error)
        }
    }
    
    private func generateData(count: Int) {
        do {
            var items = [SimpleData]()
            for _ in 0..<count {
                let nameSize = Int.random(in: 2 ... 10)
                let randomName = makeHiraganaName(nameSize)
                let customer = SimpleData(name: randomName)
                items.append(customer)
            }
            
            _ = items.map { modelContext.insert($0) }
            try modelContext.save()
        } catch {
            print(error)
        }
        
        // ランダムな名前を生成する関数（ひらがな）
        func makeHiraganaName(_ length: Int) -> String {
            let chars: [Character] = Array("あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん")
            var result = String()
            for _ in 0..<length {
                // 45音 + ん = 46文字
                let pos = Int.random(in: 0..<46)
                result.append(chars[pos])
            }
            return result
        }
    }
}
