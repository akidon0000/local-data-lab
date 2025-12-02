//
//  IndexBar.swift
//  LocalDataLab
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


// MARK: - 汎用：インデックス付きジャンプリスト
//
// List と ScrollViewReader を内包し、以下を提供する汎用コンポーネント：
// - サイドバーインデックス（IndexBar）との連携
// - セクション先頭に不可視アンカーを自動挿入（.id(sectionKey)）
// - データ読み込み後に pending なアンカーへ自動スクロール
// - 上方向プリペンド後に、所定の ID 行へ位置復元
//
// ドメイン固有のデータ取得やプリフェッチは呼び出し側で実装し、
// onSelectIndexKey でキー選択イベントを受け取って処理してください。
struct IndexedList<Item, ID: Hashable, Row: View>: View {
    // 表示対象のアイテム
    let items: [Item]
    // 行 ID に使う KeyPath（scrollTo と同一値を使用）
    let id: KeyPath<Item, ID>
    // 各アイテムが属するセクションキー（例：五十音の「あ/か/...」）
    let sectionKey: (Item) -> String
    // サイドバーに表示するキー一覧（表示順）
    let keys: [String]

    // 現在のインデックスキー（UI 表示用）
    @Binding var currentIndexKey: String?
    // 読み込み完了後にスクロールすべきアンカーキー（存在確認は内部で行う）
    @Binding var pendingScrollAnchorKey: String?
    // 上方向プリペンド後に位置復元すべき行 ID（存在確認は内部で行う）
    @Binding var stickToIDAfterPrepend: ID?

    // 行ビューのビルダー（index, item）
    let row: (Int, Item) -> Row
    // インデックスキー選択時の通知（データ読み込み等は呼び出し側で実行）
    let onSelectIndexKey: (String) -> Void

    // アイテムのID配列（Equatable）を変化検知に利用
    private var identityList: [ID] {
        items.map { $0[keyPath: id] }
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(Array(items.enumerated()), id: \.offset) { pair in
                    let index = pair.offset
                    let item = pair.element
                    // セクション先頭に不可視アンカーを挿入して、キー単位での scrollTo を可能にする
                    if isNewSection(at: index) {
                        Color.clear
                            .frame(height: 0.0001)
                            .id(sectionKey(item))
                    }

                    // 行本体（scrollTo(ID) に対応するよう ForEach の id と一致させる）
                    row(index, item)
                        .id(item[keyPath: id])
                }
            }
            
            // データ更新時に、必要であればアンカーまたは ID 復元へスクロール
//            .onChange(of: identityList) { _ in
//                // 位置復元を最優先（アニメーションなし）
//                if let restoreId = stickToIDAfterPrepend {
//                    withAnimation(.none) {
//                        proxy.scrollTo(restoreId, anchor: .top)
//                    }
//                    stickToIDAfterPrepend = nil
//                    return
//                }
//
//                // インデックスジャンプの pending があり、該当セクションが揃っていればスクロール
//                if let key = pendingScrollAnchorKey, containsSection(key) {
//                    withAnimation(.easeInOut) {
//                        proxy.scrollTo(key, anchor: .top)
//                    }
//                    pendingScrollAnchorKey = nil
//                }
//            }
//            // サイドバーインデックスを重ねる
//            .overlay(alignment: .trailing) {
//                IndexBar(keys: keys, currentKey: $currentIndexKey) { key in
//                    onSelectIndexKey(key)
//                }
//                .padding(.trailing, 4)
//            }
        }
    }

    private func isNewSection(at index: Int) -> Bool {
        guard index >= 0 && index < items.count else { return false }
        if index == 0 { return true }
        let curr = sectionKey(items[index])
        let prev = sectionKey(items[index - 1])
        return curr != prev
    }

    private func containsSection(_ key: String) -> Bool {
        items.contains { item in sectionKey(item) == key }
    }
}


// MARK: - セクション化されたデータ用：IndexedSection と SectionedIndexedList
/// セクション単位でアイテムを保持するための軽量構造体
struct IndexedSection<Item, ID: Hashable>: Hashable where ID: Hashable {
    let key: String
    var items: [Item]

    static func == (lhs: IndexedSection<Item, ID>, rhs: IndexedSection<Item, ID>) -> Bool {
        lhs.key == rhs.key
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
}

/// セクション配列をそのまま描画する IndexedList のセクション版
struct SectionedIndexedList<Item, ID: Hashable, Row: View, SectionHeader: View>: View {
    // セクション配列
    let sections: [IndexedSection<Item, ID>]
    // 行 ID に使う KeyPath（scrollTo と同一値を使用）
    let id: KeyPath<Item, ID>
    // サイドバーに表示するキー一覧（表示順）
    let keys: [String]

    // 現在のインデックスキー（UI 表示用）
    @Binding var currentIndexKey: String?
    // 読み込み完了後にスクロールすべきアンカーキー
    @Binding var pendingScrollAnchorKey: String?
    // 上方向プリペンド後に位置復元すべき行 ID
    @Binding var stickToIDAfterPrepend: ID?

    // セクションヘッダービュー（key から生成）
    let header: (String) -> SectionHeader
    // 行ビューのビルダー（index, item）
    let row: (Int, Item) -> Row
    // インデックスキー選択時の通知
    let onSelectIndexKey: (String) -> Void

    // 変化検知用の同値比較可能な ID 群（セクションキーも含める）
    private var identityList: [String] {
        var result: [String] = []
        for section in sections {
            result.append("S:\\(section.key)")
            for item in section.items {
                result.append("I:\\(String(describing: item[keyPath: id]))")
            }
        }
        return result
    }

    var body: some View {
        ScrollViewReader { proxy in
			List {
				ForEach(sections, id: \.key) { section in
					Section {
						ForEach(section.items.indices, id: \.self) { index in
							let item = section.items[index]
							row(index, item)
								.id(item[keyPath: id])
						}
					} header: {
						header(section.key)
							.id(section.key)
					}
					.sectionIndexLabel(section.key)
				}
			}
            // データ更新時に、必要であればアンカーまたは ID 復元へスクロール
//            .onChange(of: identityList) { _ in
//                // 位置復元を最優先（アニメーションなし）
//                if let restoreId = stickToIDAfterPrepend {
//                    withAnimation(.none) {
//                        proxy.scrollTo(restoreId, anchor: .top)
//                    }
//                    stickToIDAfterPrepend = nil
//                    return
//                }
//
//                // インデックスジャンプの pending があり、該当セクションが揃っていればスクロール
//                if let key = pendingScrollAnchorKey, containsSection(key) {
//                    withAnimation(.easeInOut) {
//                        proxy.scrollTo(key, anchor: .top)
//                    }
//                    pendingScrollAnchorKey = nil
//                }
//            }
            // サイドバーインデックスを重ねる
//            .overlay(alignment: .trailing) {
//                IndexBar(keys: keys, currentKey: $currentIndexKey) { key in
//                    onSelectIndexKey(key)
//                }
//                .padding(.trailing, 4)
//            }
        }
    }

    private func containsSection(_ key: String) -> Bool {
        sections.contains { $0.key == key }
    }
}

