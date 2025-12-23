//
//  UserPostListView.swift
//  LocalDataLab
//
//  Created by Akihiro Matsuyama on 2025/12/03.
//

import SwiftData
import SwiftUI

struct UserPostListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \User.name, order: .forward) private var users: [User]
    @State private var toastMessage: String? = nil

    var body: some View {
        List {
            ForEach(users, id: \.id) { user in
                Section {
                    ForEach(user.posts, id: \.id) { post in
                        HStack {
                            Text(post.title)
                            Spacer()
                            Button(action: {
                                deletePost(post)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    Button(action: {
                        addPost(to: user)
                    }) {
                        Label("投稿を追加", systemImage: "plus.circle")
                    }
                } header: {
                    HStack {
                        Text("\(user.name) (\(user.posts.count)件)")
                        Spacer()
                        Button(action: {
                            deleteUser(user)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
        .navigationTitle("User & Post (\(users.count)人)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) { ToolBarView() }
        }
        .toast(message: $toastMessage, title: "通知")
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
                Button("ユーザー1人追加") { generateData(userCount: 1, postsPerUser: 3) }
                Button("ユーザー5人追加") { generateData(userCount: 5, postsPerUser: 3) }
                Button("ユーザー10人追加") { generateData(userCount: 10, postsPerUser: 5) }
                Button("ユーザー100人追加") { generateData(userCount: 100, postsPerUser: 5) }
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    private func deleteAllData() {
        do {
            try modelContext.delete(model: User.self)
            try modelContext.delete(model: Post.self)
            showToastMessage("全てのデータを削除しました")
        } catch {
            print("🚨", error)
            showToastMessage("削除に失敗しました")
        }
    }

    private func deleteUser(_ user: User) {
        do {
            modelContext.delete(user)
            try modelContext.save()
            showToastMessage("\(user.name)を削除しました")
        } catch {
            print("🚨", error)
            showToastMessage("削除に失敗しました")
        }
    }

    private func deletePost(_ post: Post) {
        do {
            modelContext.delete(post)
            try modelContext.save()
            showToastMessage("投稿を削除しました")
        } catch {
            print("🚨", error)
            showToastMessage("削除に失敗しました")
        }
    }

    private func addPost(to user: User) {
        do {
            let post = Post(title: "新しい投稿 - \(Date().formatted())", user: user)
            modelContext.insert(post)
            try modelContext.save()
            showToastMessage("投稿を追加しました")
        } catch {
            print("🚨", error)
            showToastMessage("投稿の追加に失敗しました")
        }
    }

    private func generateData(userCount: Int, postsPerUser: Int) {
        let startTime = Date()
        do {
            let names = ["太郎", "花子", "次郎", "美咲", "健太", "由美", "大輔", "さくら", "拓也", "愛"]

            for i in 0..<userCount {
                let user = User(name: names[i % names.count] + "\(i + 1)")
                modelContext.insert(user)

                for j in 0..<postsPerUser {
                    let post = Post(
                        title: "投稿\(j + 1): SwiftDataのリレーション実装",
                        user: user
                    )
                    modelContext.insert(post)
                }
            }

            try modelContext.save()
            let elapsed = Date().timeIntervalSince(startTime)
            showToastMessage("\(userCount)人のユーザーと\(userCount * postsPerUser)件の投稿を追加しました（\(String(format: "%.2f", elapsed))秒）")
        } catch {
            print("🚨", error)
            showToastMessage("データの生成に失敗しました")
        }
    }

    private func showToastMessage(_ message: String) {
        toastMessage = message
    }
}
