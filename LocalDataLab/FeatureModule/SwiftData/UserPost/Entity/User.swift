//
//  User.swift
//  LocalDataLab
//
//  Created by Akihiro Matsuyama on 2025/12/03.
//

import Foundation
import SwiftData

@Model
class User {
    @Attribute(.unique) var id: String
    var name: String
    @Relationship(deleteRule: .cascade) var posts: [Post]

    init(id: String = UUID().uuidString, name: String = "", posts: [Post] = []) {
        self.id = id
        self.name = name
        self.posts = posts
    }
}
