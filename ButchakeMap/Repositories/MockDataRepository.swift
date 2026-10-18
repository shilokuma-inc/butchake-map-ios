//
//  MockDataRepository.swift
//  ButchakeMap
//
//  投稿をメモリ上に持つリポジトリ。App で 1 つ作り、.environment で全画面に渡す。
//  いいね・スター・投稿の追加・編集・削除はすべてここを経由し、各画面は同じ posts を見て同期する。
//  永続化・サーバー通信はしない（再起動で初期データに戻る）。
//

import Foundation
import Observation

@MainActor
@Observable
final class MockDataRepository {
    /// 公開済み・下書きを含むすべての投稿
    private(set) var posts: [Post]

    /// 「自分」のニックネーム。authorName がこれと一致する投稿を自分の投稿とみなす
    let currentUserName: String

    init(posts: [Post] = MockData.posts(), currentUserName: String = MockData.currentUserName) {
        self.posts = posts
        self.currentUserName = currentUserName
    }

    // MARK: - 読み出し

    /// 公開済みの投稿（新しい順）
    var publishedPosts: [Post] {
        posts.filter { !$0.isDraft }.sorted { $0.createdAt > $1.createdAt }
    }

    /// 自分の下書き（新しい順）
    var drafts: [Post] {
        posts.filter { $0.isDraft && isMine($0) }.sorted { $0.createdAt > $1.createdAt }
    }

    /// 自分が公開した投稿（新しい順）
    var myPosts: [Post] {
        publishedPosts.filter(isMine)
    }

    /// スター（保存）した公開済みの投稿（新しい順）
    var starredPosts: [Post] {
        publishedPosts.filter(\.isStarred)
    }

    func post(id: Post.ID) -> Post? {
        posts.first { $0.id == id }
    }

    func isMine(_ post: Post) -> Bool {
        post.authorName == currentUserName
    }

    // MARK: - いいね・スター

    func toggleLike(postID: Post.ID) {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else {
            return
        }
        posts[index].isLiked.toggle()
        posts[index].likeCount = max(0, posts[index].likeCount + (posts[index].isLiked ? 1 : -1))
    }

    func toggleStar(postID: Post.ID) {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else {
            return
        }
        posts[index].isStarred.toggle()
        posts[index].starCount = max(0, posts[index].starCount + (posts[index].isStarred ? 1 : -1))
    }

    // MARK: - 作成・編集・削除

    /// 下書きとして保存する。保存した時刻を createdAt にする
    /// - Parameter isNew: true なら新しい投稿として追加し、false なら同じ id の下書きを置き換える
    /// - Throws: 新規なのに同じ id がある / 更新先が削除されている / 更新先が公開済み（下書きには戻せない）とき
    func saveDraft(_ post: Post, isNew: Bool) throws(PostSaveError) {
        let index = try storedIndex(of: post.id, isNew: isNew)
        if let index, !posts[index].isDraft {
            throw .alreadyPublished
        }
        var draft = post
        draft.isDraft = true
        draft.createdAt = Date()
        store(draft, at: index)
    }

    /// 公開する。新規・下書きの投稿は公開した時刻を createdAt にし、公開済みの投稿の編集では元の createdAt を保つ
    /// - Parameter isNew: true なら新しい投稿として追加し、false なら同じ id の投稿を置き換える
    /// - Throws: 新規なのに同じ id がある / 更新先が削除されているとき
    func publish(_ post: Post, isNew: Bool) throws(PostSaveError) {
        let index = try storedIndex(of: post.id, isNew: isNew)
        var published = post
        if let index, !posts[index].isDraft {
            published.createdAt = posts[index].createdAt
        } else {
            published.createdAt = Date()
        }
        published.isDraft = false
        store(published, at: index)
    }

    func delete(postID: Post.ID) {
        posts.removeAll { $0.id == postID }
    }

    /// 新規なら同じ id が無いことを、更新なら同じ id があることを確かめ、置き換える位置を返す（新規は nil）。
    /// 編集中に別の画面で削除された投稿を、保存で復活させないため
    private func storedIndex(of postID: Post.ID, isNew: Bool) throws(PostSaveError) -> Int? {
        let index = posts.firstIndex { $0.id == postID }
        if isNew {
            guard index == nil else {
                throw .alreadyExists
            }
            return nil
        }
        guard let index else {
            throw .notFound
        }
        return index
    }

    private func store(_ post: Post, at index: Int?) {
        if let index {
            posts[index] = post
        } else {
            posts.append(post)
        }
    }
}

/// 投稿を保存・公開できなかった理由
nonisolated enum PostSaveError: Error, Equatable, Sendable {
    /// 新規として渡した投稿と同じ id の投稿がすでにある
    case alreadyExists
    /// 更新しようとした投稿が無い（編集中に削除された）
    case notFound
    /// 公開済みの投稿は下書きに戻せない
    case alreadyPublished
}

extension MockDataRepository {
    /// Preview 用に初期モックデータを入れたリポジトリ
    static var preview: MockDataRepository {
        MockDataRepository()
    }
}
