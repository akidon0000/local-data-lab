////
////  BusinessCardActor.swift
////  localDB-sampleer
////
////  Created by Akihiro Matsuyama on 2025/10/11.
////
//
//import Foundation
//import SwiftData
//
///// 名刺管理用のグローバルアクター
//@globalActor
//actor BusinessCardActor {
//    static let shared = BusinessCardActor()
//    
//    private init() {}
//}
//
///// 名刺管理のビジネスロジックを担当するクラス
//@BusinessCardActor
//class BusinessCardManager {
//    static let shared = BusinessCardManager()
//    
//    private init() {}
//    
//    // MARK: - 名刺の追加
//    
//    /// 単一の名刺を追加
//    func addBusinessCard(
//        name: String,
//        company: String,
//        position: String,
//        to modelContext: ModelContext
//    ) throws {
//        guard !name.isEmpty && !company.isEmpty else {
//            throw BusinessCardError.invalidInput
//        }
//        
//        let newCard = BusinessCard(
//            name: name,
//            company: company,
//            position: position
//        )
//        
//        modelContext.insert(newCard)
//        try modelContext.save()
//    }
//    
//    /// 指定件数の名刺を一括追加
//    func addBusinessCards(
//        count: Int,
//        to modelContext: ModelContext
//    ) async throws {
//        guard count > 0 else { return }
//        
//        let companies = getCompanies()
//        let positions = getPositions()
//        let firstNames = getFirstNames()
//        let lastNames = getLastNames()
//        
//        // バッチ処理でパフォーマンスを向上
//        let batchSize = 100
//        let batches = (count + batchSize - 1) / batchSize
//        
//        for batch in 0..<batches {
//            let startIndex = batch * batchSize
//            let endIndex = min(startIndex + batchSize, count)
//            let currentBatchSize = endIndex - startIndex
//            
//            // バックグラウンドでデータ生成
//            let newCards = await Task.detached {
//                var cards: [BusinessCard] = []
//                for _ in 0..<currentBatchSize {
//                    let lastName = lastNames.randomElement()!
//                    let firstName = firstNames.randomElement()!
//                    let company = companies.randomElement()!
//                    let position = positions.randomElement()!
//                    
//                    let newCard = BusinessCard(
//                        name: "\(lastName) \(firstName)",
//                        company: company,
//                        position: position
//                    )
//                    cards.append(newCard)
//                }
//                return cards
//            }.value
//            
//            // データベースに保存
//            for card in newCards {
//                modelContext.insert(card)
//            }
//            
//            try modelContext.save()
//            
//            // 少し待機してUIの応答性を保つ
//            if batch < batches - 1 {
//                try await Task.sleep(nanoseconds: 10_000_000) // 0.01秒
//            }
//        }
//    }
//    
//    /// サンプルデータを生成
//    func generateSampleData(to modelContext: ModelContext) throws {
//        let sampleCards = [
//            ("田中 太郎", "株式会社サンプル", "営業部長"),
//            ("佐藤 花子", "テクノロジー株式会社", "エンジニア"),
//            ("鈴木 一郎", "デザイン事務所", "デザイナー"),
//            ("高橋 美咲", "マーケティング会社", "マネージャー"),
//            ("山田 健太", "コンサルティング会社", "コンサルタント")
//        ]
//        
//        for (name, company, position) in sampleCards {
//            // 重複チェック
//            let descriptor = FetchDescriptor<BusinessCard>(
//                predicate: #Predicate { card in
//                    card.name == name && card.company == company
//                }
//            )
//            
//            let existingCards = try modelContext.fetch(descriptor)
//            if existingCards.isEmpty {
//                try addBusinessCard(
//                    name: name,
//                    company: company,
//                    position: position,
//                    to: modelContext
//                )
//            }
//        }
//    }
//    
//    // MARK: - 名刺の削除
//    
//    /// 単一の名刺を削除
//    func deleteBusinessCard(
//        _ card: BusinessCard,
//        from modelContext: ModelContext
//    ) throws {
//        modelContext.delete(card)
//        try modelContext.save()
//    }
//    
//    /// 指定件数の名刺を削除（最新から）
//    func deleteBusinessCards(
//        count: Int,
//        from modelContext: ModelContext
//    ) async throws {
//        guard count > 0 else { return }
//        
//        let batchSize = 100
//        var remainingCount = count
//        
//        while remainingCount > 0 {
//            let currentBatchSize = min(batchSize, remainingCount)
//            
//            // 最新の名刺から削除
//            var descriptor = FetchDescriptor<BusinessCard>(
//                sortBy: [SortDescriptor(\.name, order: .reverse)]
//            )
//            descriptor.fetchLimit = currentBatchSize
//            
//            let cardsToDelete = try modelContext.fetch(descriptor)
//            
//            if cardsToDelete.isEmpty {
//                break
//            }
//            
//            for card in cardsToDelete {
//                modelContext.delete(card)
//            }
//            
//            try modelContext.save()
//            
//            remainingCount -= cardsToDelete.count
//            
//            // UIの応答性を保つため少し待機
//            if remainingCount > 0 {
//                try await Task.sleep(nanoseconds: 10_000_000) // 0.01秒
//            }
//        }
//    }
//    
//    /// 全ての名刺を削除
//    func deleteAllBusinessCards(from modelContext: ModelContext) async throws {
//        // バッチサイズで分割して削除
//        let batchSize = 100
//        let descriptor = FetchDescriptor<BusinessCard>()
//        
//        while true {
//            var limitedDescriptor = descriptor
//            limitedDescriptor.fetchLimit = batchSize
//            
//            let cardsToDelete = try modelContext.fetch(limitedDescriptor)
//            
//            if cardsToDelete.isEmpty {
//                break
//            }
//            
//            for card in cardsToDelete {
//                modelContext.delete(card)
//            }
//            
//            try modelContext.save()
//            
//            // UIの応答性を保つため少し待機
//            try await Task.sleep(nanoseconds: 10_000_000) // 0.01秒
//        }
//    }
//}
//
//// MARK: - エラー定義
//
//enum BusinessCardError: LocalizedError {
//    case invalidInput
//    case saveFailed(String)
//    case deleteFailed(String)
//    
//    var errorDescription: String? {
//        switch self {
//        case .invalidInput:
//            return "入力データが無効です"
//        case .saveFailed(let message):
//            return "保存に失敗しました: \(message)"
//        case .deleteFailed(let message):
//            return "削除に失敗しました: \(message)"
//        }
//    }
//}
//
//// MARK: - データ生成用の配列
//
//@BusinessCardActor
//extension BusinessCardManager {
//    // 会社名の配列を取得
//    private func getCompanies() -> [String] {
//        return [
//            // IT・テクノロジー系
//            "株式会社テクノロジー", "システム開発株式会社", "ソフトウェア株式会社", "IT株式会社", "デジタル株式会社",
//            "株式会社イノベーション", "株式会社フューチャー", "株式会社アドバンス", "株式会社プログレス", "株式会社サクセス",
//            "クラウド株式会社", "データ株式会社", "AI株式会社", "IoT株式会社", "ブロックチェーン株式会社",
//            "サイバー株式会社", "ネット株式会社", "ウェブ株式会社", "モバイル株式会社", "アプリ株式会社",
//            
//            // コンサルティング・サービス系
//            "コンサルティング株式会社", "ビジネス株式会社", "マネジメント株式会社", "ストラテジー株式会社", "アドバイザリー株式会社",
//            "プロフェッショナル株式会社", "エキスパート株式会社", "スペシャリスト株式会社", "コンサル株式会社", "アナリスト株式会社",
//            "リサーチ株式会社", "調査株式会社", "分析株式会社", "企画株式会社", "戦略株式会社",
//            
//            // マーケティング・広告系
//            "マーケティング株式会社", "広告株式会社", "宣伝株式会社", "PR株式会社", "ブランディング株式会社",
//            "クリエイティブ株式会社", "デザイン株式会社", "アート株式会社", "制作株式会社", "企画制作株式会社",
//            "メディア株式会社", "コンテンツ株式会社", "エンターテイメント株式会社", "映像株式会社", "音響株式会社",
//            
//            // 製造・工業系
//            "製造株式会社", "工業株式会社", "機械株式会社", "電機株式会社", "電子株式会社",
//            "精密株式会社", "技術株式会社", "エンジニアリング株式会社", "開発株式会社", "研究株式会社",
//            "化学株式会社", "材料株式会社", "素材株式会社", "金属株式会社", "プラスチック株式会社",
//            
//            // 金融・保険系
//            "金融株式会社", "銀行株式会社", "証券株式会社", "保険株式会社", "投資株式会社",
//            "ファイナンス株式会社", "資産運用株式会社", "信託株式会社", "リース株式会社", "クレジット株式会社",
//            "決済株式会社", "フィンテック株式会社", "暗号資産株式会社", "投資顧問株式会社", "資産管理株式会社"
//        ]
//    }
//    
//    // 役職の配列を取得
//    private func getPositions() -> [String] {
//        return [
//            // 経営層
//            "代表取締役", "取締役", "執行役員", "常務取締役", "専務取締役", "副社長", "社長", "会長", "CEO", "CTO",
//            "CFO", "COO", "CIO", "CMO", "CHRO", "CDO", "CPO", "CSO", "CCO", "CRO",
//            
//            // 管理職
//            "部長", "副部長", "課長", "副課長", "係長", "主任", "班長", "グループ長", "チーフ", "リーダー",
//            "マネージャー", "シニアマネージャー", "ゼネラルマネージャー", "エリアマネージャー", "ブランチマネージャー",
//            "プロダクトマネージャー", "プロジェクトマネージャー", "プログラムマネージャー", "オペレーションマネージャー", "セールスマネージャー",
//            
//            // 技術職
//            "エンジニア", "シニアエンジニア", "リードエンジニア", "プリンシパルエンジニア", "アーキテクト", "テックリード",
//            "フロントエンドエンジニア", "バックエンドエンジニア", "フルスタックエンジニア", "インフラエンジニア", "DevOpsエンジニア",
//            "データエンジニア", "MLエンジニア", "AIエンジニア", "セキュリティエンジニア", "QAエンジニア",
//            "システムエンジニア", "ネットワークエンジニア", "データベースエンジニア", "クラウドエンジニア", "モバイルエンジニア",
//            
//            // デザイン職
//            "デザイナー", "シニアデザイナー", "リードデザイナー", "アートディレクター", "クリエイティブディレクター",
//            "UIデザイナー", "UXデザイナー", "UI/UXデザイナー", "プロダクトデザイナー", "グラフィックデザイナー",
//            "ウェブデザイナー", "モーションデザイナー", "3Dデザイナー", "イラストレーター", "フォトグラファー",
//            
//            // 営業・マーケティング職
//            "営業", "シニア営業", "営業主任", "営業課長", "営業部長", "セールス", "アカウントマネージャー",
//            "インサイドセールス", "フィールドセールス", "カスタマーサクセス", "ビジネスデベロップメント", "パートナーセールス",
//            "マーケティング", "マーケター", "デジタルマーケター", "コンテンツマーケター", "プロダクトマーケター",
//            "ブランドマネージャー", "PR", "広報", "宣伝", "イベントプランナー"
//        ]
//    }
//    
//    // 名前の配列を取得
//    private func getFirstNames() -> [String] {
//        return [
//            // 伝統的な男性名
//            "太郎", "一郎", "健太", "大輔", "翔太", "裕太", "直樹", "雅人", "博之", "隆",
//            "修", "浩", "誠", "剛", "学", "明", "勇", "進", "豊", "正",
//            "和也", "拓也", "哲也", "達也", "雄也", "秀也", "克也", "智也", "淳也", "慎也",
//            "慎一", "康一", "洋一", "昭一", "健一", "良一", "信一", "義一", "敏一", "光一",
//            
//            // 伝統的な女性名
//            "花子", "美咲", "由美", "恵子", "麻衣", "美香", "智子", "真理", "加奈", "綾子",
//            "典子", "理恵", "千春", "美穂", "純子", "香織", "奈美", "幸子", "陽子", "洋子",
//            "美樹", "美紀", "美貴", "美希", "美季", "美喜", "美輝", "美記", "美規", "美基",
//            "愛", "恵", "恵美", "恵子", "恵里", "恵理", "恵利", "恵梨", "恵莉", "恵璃",
//            
//            // 現代的な男性名
//            "翔", "蓮", "大翔", "陽翔", "結翔", "悠翔", "颯", "颯太", "颯人", "颯真",
//            "陽", "陽太", "陽人", "陽斗", "陽向", "陽翔", "陽大", "陽介", "陽平", "陽一",
//            "蒼", "蒼太", "蒼人", "蒼斗", "蒼空", "蒼真", "蒼介", "蒼平", "蒼一", "蒼大",
//            "悠", "悠太", "悠人", "悠斗", "悠真", "悠介", "悠平", "悠一", "悠大", "悠希",
//            
//            // 現代的な女性名
//            "結", "結愛", "結菜", "結衣", "結花", "結華", "結香", "結佳", "結加", "結果",
//            "咲", "咲良", "咲希", "咲子", "咲美", "咲恵", "咲織", "咲音", "咲月", "咲空",
//            "美", "美月", "美空", "美桜", "美花", "美華", "美香", "美佳", "美加", "美果",
//            "愛", "愛美", "愛子", "愛花", "愛華", "愛香", "愛佳", "愛加", "愛果", "愛夏"
//        ]
//    }
//    
//    // 苗字の配列を取得
//    private func getLastNames() -> [String] {
//        return [
//            // 一般的な苗字（上位100位）
//            "田中", "佐藤", "鈴木", "高橋", "山田", "渡辺", "伊藤", "中村", "小林", "加藤",
//            "吉田", "山本", "松本", "井上", "木村", "林", "斎藤", "清水", "山崎", "森",
//            "池田", "橋本", "山口", "石川", "中島", "前田", "藤田", "後藤", "岡田", "長谷川",
//            "村上", "近藤", "石田", "遠藤", "青木", "坂本", "福田", "太田", "西村", "藤井",
//            "岡本", "松田", "中川", "中野", "原田", "小川", "竹内", "和田", "中山", "石井",
//            "上田", "森田", "原", "柴田", "酒井", "工藤", "横山", "宮崎", "宮本", "内田",
//            "高木", "安藤", "島田", "谷口", "大野", "高田", "丸山", "今井", "河野", "藤原",
//            "小野", "田村", "吉川", "五十嵐", "三浦", "白石", "関", "杉山", "大塚", "平野",
//            "菅原", "武田", "新井", "小島", "南", "千葉", "大西", "岩田", "松井", "菊地",
//            "野口", "木下", "佐々木", "野村", "松尾", "菅野", "佐野", "山下", "大橋", "杉本"
//        ]
//    }
//}
