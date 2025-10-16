//
//  Customers.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/11.
//

import Foundation
import SwiftData

// 既存 Customers を残しつつ、新たな複雑モデル群を追加

@Model class Customers {
    #Index<Customers>([\.name], [\.creationDate], [\.name, \.creationDate])
    
    @Attribute(.unique) var id: String
    var name: String
    var creationDate: Date
    
    init(name: String = "", createdAt: Date = .now) {
        self.id = UUID().uuidString
        self.name = name
        self.creationDate = createdAt
    }
    
    static func predicate(name: String) -> Predicate<Customers> {
        return #Predicate<Customers> { card in
            if name == "" {
                return true
            } else {
                return card.name.contains(name)
            }
        }
    }
}

// MARK: - 複雑モデル（名刺・取引先ドメイン）

@Model final class Company {
    @Attribute(.unique) var id: String
    var name: String
    var kana: String
    var domain: String?
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var departments: [Department]
    @Relationship(deleteRule: .nullify, inverse: \Contact.company) var contacts: [Contact]
    
    init(name: String, kana: String, domain: String? = nil, createdAt: Date = .now) {
        self.id = UUID().uuidString
        self.name = name
        self.kana = kana
        self.domain = domain
        self.createdAt = createdAt
        self.departments = []
        self.contacts = []
    }
}

@Model final class Department {
    @Attribute(.unique) var id: String
    var name: String
    var kana: String
    @Relationship(inverse: \Company.departments) var company: Company?
    
    init(name: String, kana: String, company: Company? = nil) {
        self.id = UUID().uuidString
        self.name = name
        self.kana = kana
        self.company = company
    }
}

@Model final class Address {
    @Attribute(.unique) var id: String
    var postalCode: String
    var prefecture: String
    var city: String
    var street: String
    var building: String?
    var country: String
    
    init(postalCode: String, prefecture: String, city: String, street: String, building: String? = nil, country: String = "JP") {
        self.id = UUID().uuidString
        self.postalCode = postalCode
        self.prefecture = prefecture
        self.city = city
        self.street = street
        self.building = building
        self.country = country
    }
}

@Model final class Tag {
    @Attribute(.unique) var id: String
    var name: String
    var createdAt: Date
    
    init(name: String, createdAt: Date = .now) {
        self.id = UUID().uuidString
        self.name = name
        self.createdAt = createdAt
    }
}

@Model final class Contact {
    @Attribute(.unique) var id: String
    // 氏名
    var familyName: String
    var givenName: String
    var familyKana: String
    var givenKana: String
    var displayName: String { "\(familyName) \(givenName)" }
    
    // 勤務先情報
    @Relationship var company: Company?
    @Relationship var department: Department?
    var title: String?
    
    // 連絡先
    var email: String?
    var phoneMobile: String?
    var phoneWork: String?
    var website: String?
    
    // 住所
    @Relationship(deleteRule: .cascade) var addresses: [Address]
    
    // タグ（多対多）
    @Relationship var tags: [Tag]
    
    // 監査
    var createdAt: Date
    var updatedAt: Date
    
    init(
        familyName: String,
        givenName: String,
        familyKana: String,
        givenKana: String,
        company: Company? = nil,
        department: Department? = nil,
        title: String? = nil,
        email: String? = nil,
        phoneMobile: String? = nil,
        phoneWork: String? = nil,
        website: String? = nil,
        addresses: [Address] = [],
        tags: [Tag] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = UUID().uuidString
        self.familyName = familyName
        self.givenName = givenName
        self.familyKana = familyKana
        self.givenKana = givenKana
        self.company = company
        self.department = department
        self.title = title
        self.email = email
        self.phoneMobile = phoneMobile
        self.phoneWork = phoneWork
        self.website = website
        self.addresses = addresses
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// インデックス用キー（五十音）
extension Contact {
    var indexKey: String {
        guard let first = familyKana.first ?? givenKana.first else { return "#" }
        switch first {
        case "あ","い","う","え","お": return "あ"
        case "か","き","く","け","こ": return "か"
        case "さ","し","す","せ","そ": return "さ"
        case "た","ち","つ","て","と": return "た"
        case "な","に","ぬ","ね","の": return "な"
        case "は","ひ","ふ","へ","ほ": return "は"
        case "ま","み","む","め","も": return "ま"
        case "や","ゆ","よ": return "や"
        case "ら","り","る","れ","ろ": return "ら"
        case "わ","を","ん": return "わ"
        default: return "#"
        }
    }
}
