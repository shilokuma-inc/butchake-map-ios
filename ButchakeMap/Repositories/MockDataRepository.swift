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

    /// 下書きとして保存する。同じ id の投稿があれば置き換え、無ければ追加する
    func saveDraft(_ post: Post) {
        var draft = post
        draft.isDraft = true
        draft.createdAt = Date()
        upsert(draft)
    }

    /// 公開する。下書き・新規の投稿は公開した時刻を createdAt にし、公開済みの投稿の編集では createdAt を保つ
    func publish(_ post: Post) {
        var published = post
        let wasPublished = self.post(id: post.id).map { !$0.isDraft } ?? false
        if !wasPublished {
            published.createdAt = Date()
        }
        published.isDraft = false
        upsert(published)
    }

    func delete(postID: Post.ID) {
        posts.removeAll { $0.id == postID }
    }

    private func upsert(_ post: Post) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index] = post
        } else {
            posts.append(post)
        }
    }
}

extension MockDataRepository {
    /// Preview 用に初期モックデータを入れたリポジトリ
    static var preview: MockDataRepository {
        MockDataRepository()
    }
}
