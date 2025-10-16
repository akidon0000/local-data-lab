//
//  FewDataIndexComplicatedView.swift
//  localDB-sampleer
//
//  Created by Assistant on 2025/10/15.
//

import SwiftUI
import SwiftData
import Dispatch

struct FewDataIndexComplicatedView: View {
    @Environment(\.modelContext) var modelContext
    @State private var contacts: [Contact] = []
    @State private var sections: [IndexedSection<Contact, String>] = []
    @State private var fetchMs: Double? = nil
    @State private var sectionMs: Double? = nil
    @State private var paintMs: Double? = nil
    @State private var uiStartTime: DispatchTime? = nil
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    ForEach(sections, id: \.key) { section in
                        Section {
                            ForEach(section.items, id: \.id) { contact in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(contact.displayName)
                                        .font(.headline)
                                    if let company = contact.company?.name {
                                        Text(company)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    if let title = contact.title, !title.isEmpty {
                                        Text(title)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                                .onAppear {
                                    if paintMs == nil, let start = uiStartTime {
                                        let now = DispatchTime.now()
                                        let ms = Double(now.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
                                        paintMs = ms
                                    }
                                }
                            }
                        } header: {
                            Text(section.key)
                        }
                        .sectionIndexLabel(section.key)
                    }
                }
                if fetchMs != nil || sectionMs != nil || paintMs != nil || isLoading {
                    VStack(alignment: .trailing, spacing: 4) {
                        if isLoading { Text("Loading...").font(.caption).foregroundStyle(.secondary) }
                        if let f = fetchMs { Text(String(format: "fetch: %.1f ms", f)).font(.caption2) }
                        if let s = sectionMs { Text(String(format: "section/sort: %.1f ms", s)).font(.caption2) }
                        if let p = paintMs { Text(String(format: "first paint: %.1f ms", p)).font(.caption2) }
                        Text("arr: \(formatBytes(arrayPtrBytes))").font(.caption2)
                        Text("sec items: \(formatBytes(sectionItemsPtrBytes))").font(.caption2)
                        Text("total ptrs: \(formatBytes(arrayPtrBytes + sectionItemsPtrBytes))").font(.caption2)
                    }
                    .padding(8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding([.top, .trailing], 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
            .navigationTitle("名刺一覧 (複雑) 表示: (\(contacts.count))件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    HStack {
                        Menu {
                            Button("全て削除", role: .destructive) { deleteAll() }
                        } label: {
                            Image(systemName: "trash").foregroundColor(.red)
                        }
                        
                        Menu {
                            Button("10,000件追加") { generateContacts(count: 10000) }
                            Button("100,000件追加") { generateContacts(count: 100000) }
                        } label: {
                            Image(systemName: "plus")
                        }
                        Button {
                            reload()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .onAppear { if contacts.isEmpty { reload() } }
        }
    }
    
    private var sortedSectionKeys: [String] {
        ["あ","か","さ","た","な","は","ま","や","ら","わ"]
    }
    
    private func buildSections(from source: [Contact]) -> [IndexedSection<Contact, String>] {
        var dict: [String: [Contact]] = [:]
        for c in source {
            let key = c.indexKey
            dict[key, default: []].append(c)
        }
        var result: [IndexedSection<Contact, String>] = []
        for key in sortedSectionKeys {
            if var arr = dict[key] {
                arr.sort { lhs, rhs in
                    if lhs.familyKana == rhs.familyKana {
                        return lhs.givenKana < rhs.givenKana
                    }
                    return lhs.familyKana < rhs.familyKana
                }
                result.append(IndexedSection<Contact, String>(key: key, items: arr))
            }
        }
        for (key, arr) in dict where !sortedSectionKeys.contains(key) {
            let sorted = arr.sorted { $0.familyKana < $1.familyKana }
            result.append(IndexedSection<Contact, String>(key: key, items: sorted))
        }
        return result
    }
    
    private func deleteAll() {
        do {
            try modelContext.delete(model: Contact.self)
            try modelContext.delete(model: Company.self)
            try modelContext.delete(model: Department.self)
            try modelContext.delete(model: Address.self)
            try modelContext.delete(model: Tag.self)
            reload()
        } catch {
            print(error)
        }
    }
    
    private func generateContacts(count: Int) {
        Task {
            var companies: [Company] = []
            var tagsPool: [Tag] = []
            
            // 会社・タグのプールを先に作成
            for i in 0..<min(200, max(10, count / 500)) {
                let comp = Company(name: randomCompanyName(i), kana: randomKanaWord(3 + (i % 2)))
                companies.append(comp)
                modelContext.insert(comp)
            }
            for i in 0..<50 {
                let tag = Tag(name: randomTagName(i))
                tagsPool.append(tag)
                modelContext.insert(tag)
            }
            
            var items: [Contact] = []
            for i in 0..<count {
                let company = companies.randomElement()
                let (family, given, familyKana, givenKana) = randomJapaneseName(index: i)
                var contact = Contact(
                    familyName: family,
                    givenName: given,
                    familyKana: familyKana,
                    givenKana: givenKana,
                    company: company,
                    department: nil,
                    title: randomTitle(i),
                    email: randomEmail(index: i),
                    phoneMobile: randomPhone(),
                    phoneWork: randomPhone(),
                    website: nil
                )
                // address 追加
                contact.addresses = [randomAddress(i)]
                // タグを 0..3 付与
                let tagCount = Int.random(in: 0...3)
                if tagCount > 0 {
                    contact.tags = Array(tagsPool.shuffled().prefix(tagCount))
                }
                items.append(contact)
            }
            for c in items { modelContext.insert(c) }
            try? modelContext.save()
            await MainActor.run { reload() }
        }
    }
    
    private func reload() {
        guard !isLoading else { return }
        isLoading = true
        fetchMs = nil
        sectionMs = nil
        paintMs = nil
        uiStartTime = nil
        
        Task {
            let fetchStart = DispatchTime.now()
            var descriptor = FetchDescriptor<Contact>(
                sortBy: [
                    SortDescriptor(\Contact.familyKana, order: .forward),
                    SortDescriptor(\Contact.givenKana, order: .forward)
                ]
            )
            descriptor.predicate = nil
            descriptor.includePendingChanges = true
            let fetched = (try? modelContext.fetch(descriptor)) ?? []
            let fetchEnd = DispatchTime.now()
            let fetchDurationMs = Double(fetchEnd.uptimeNanoseconds - fetchStart.uptimeNanoseconds) / 1_000_000
            
            // セクション構築（ソート含む）計測
            let sectionStart = DispatchTime.now()
            let built = buildSections(from: fetched) // fetched は既に DB 側で並び替え済み
            let sectionEnd = DispatchTime.now()
            let sectionDurationMs = Double(sectionEnd.uptimeNanoseconds - sectionStart.uptimeNanoseconds) / 1_000_000
            
            await MainActor.run {
                contacts = fetched
                sections = built
                fetchMs = fetchDurationMs
                sectionMs = sectionDurationMs
                uiStartTime = DispatchTime.now()
                isLoading = false
            }
        }
    }
    
    private var arrayPtrBytes: Int {
        contacts.count * MemoryLayout<Contact>.stride
    }
    private var sectionItemsPtrBytes: Int {
        sections.reduce(0) { $0 + $1.items.count * MemoryLayout<Contact>.stride }
    }
    private func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        let kb = Double(bytes) / 1024
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        let mb = kb / 1024
        return String(format: "%.2f MB", mb)
    }
}

// MARK: - Random Generators
private func randomKanaWord(_ length: Int) -> String {
    let chars = Array("あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん")
    return String((0..<length).map { _ in chars.randomElement()! })
}

// 日本人名（姓・名）のランダム生成（かな付き）
// index を使って決定的に選択するため、データ生成の再現性を確保
private func randomJapaneseName(index: Int) -> (family: String, given: String, familyKana: String, givenKana: String) {
    let families: [(String, String)] = [
        ("佐藤","さとう"),("鈴木","すずき"),("高橋","たかはし"),("田中","たなか"),("伊藤","いとう"),
        ("渡辺","わたなべ"),("山本","やまもと"),("中村","なかむら"),("小林","こばやし"),("加藤","かとう"),
        ("吉田","よしだ"),("山田","やまだ"),("佐々木","ささき"),("山口","やまぐち"),("松本","まつもと"),
        ("井上","いのうえ"),("木村","きむら"),("林","はやし"),("斎藤","さいとう"),("清水","しみず")
    ]
    let givens: [(String, String)] = [
        ("太郎","たろう"),("花子","はなこ"),("健","けん"),("愛","あい"),("翔","しょう"),
        ("葵","あおい"),("陽菜","ひな"),("悠人","ゆうと"),("美咲","みさき"),("陸","りく"),
        ("結衣","ゆい"),("翔太","しょうた"),("陽斗","はると"),("七海","ななみ"),("颯太","そうた"),
        ("芽衣","めい"),("大輝","だいき"),("紗季","さき"),("蒼","あおい"),("結菜","ゆな")
    ]
    let f = families[abs(index) % families.count]
    let g = givens[abs(index / max(1, families.count) + index) % givens.count]
    return (f.0, g.0, f.1, g.1)
}

private func randomCompanyName(_ i: Int) -> String {
    let suffix = ["株式会社","合同会社","有限会社"].randomElement()!
    return "\(randomKanaWord(3 + (i % 3)))\(suffix)"
}

private func randomTagName(_ i: Int) -> String {
    let names = ["VIP","見込み","フェア交換","要注意","支払遅延","重要","外注","代理店"]
    return names[i % names.count]
}

private func randomTitle(_ i: Int) -> String {
    let titles = ["代表取締役","部長","課長","主任","担当","PM","営業"]
    return titles[i % titles.count]
}

private func randomEmail(index: Int) -> String? {
    let domains = ["example.com","corp.jp","business.co","mail.com"]
    return "user\(index % 10_000)@\(domains[index % domains.count])"
}

private func randomPhone() -> String? {
    return "0\(Int.random(in: 70...90))-\(Int.random(in: 1000...9999))-\(Int.random(in: 1000...9999))"
}

private func randomAddress(_ i: Int) -> Address {
    let prefectures = ["東京都","神奈川県","大阪府","愛知県","北海道","福岡県"]
    let p = prefectures.randomElement()!
    return Address(
        postalCode: String(format: "%03d-%04d", Int.random(in: 100...999), Int.random(in: 1000...9999)),
        prefecture: p,
        city: "\(randomKanaWord(3))市",
        street: "\(Int.random(in: 1...5))丁目\(Int.random(in: 1...30))番地",
        building: Bool.random() ? "第\(Int.random(in: 1...20))ビル" : nil,
        country: "JP"
    )
}
