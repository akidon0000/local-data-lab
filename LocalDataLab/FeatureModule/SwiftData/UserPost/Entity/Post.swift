//
//  Post.swift
//  LocalDataLab
//
//  Created by Akihiro Matsuyama on 2025/12/03.
//

import Foundation
import SwiftData

@Model
class Post {
    @Attribute(.unique) var id: String
    var title: String
    @Relationship(inverse: \User.posts) var user: User?

    init(id: String = UUID().uuidString, title: String = "", user: User? = nil) {
        self.id = id
        self.title = title
        self.user = user
    }
}
