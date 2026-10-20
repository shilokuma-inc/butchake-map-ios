//
//  MyPageViewModel.swift
//  ButchakeMap
//
//  マイページに出すプロフィールと一覧の組み立て。投稿は持たず、毎回 MockDataRepository から引く（他の画面と同期させるため）。
//  選んでいる一覧は画面の @State に MyPageSection として持ち、section に渡す
//

import Foundation

/// マイページで切り替える一覧
enum MyPageSection: String, CaseIterable, Identifiable {
    case myPosts
    case saved
    case drafts

    var id: Self { self }

    /// セグメントに出す名前
    var title: LocalizedStringResource {
        switch self {
        case .myPosts:
            "My Posts"
        case .saved:
            "Saved"
        case .drafts:
            "Drafts"
        }
    }

    /// 一覧が空のときの見出し
    var emptyTitle: LocalizedStringResource {
        switch self {
        case .myPosts:
            "No posts yet"
        case .saved:
            "No saved posts"
        case .drafts:
            "No drafts"
        }
    }

    /// 一覧が空のときの説明
    var emptyDescription: LocalizedStringResource {
        switch self {
        case .myPosts:
            "Share your big three from the Post tab."
        case .saved:
            "Tap the star on a post to save it here."
        case .drafts:
            "Drafts you save from the Post tab appear here."
        }
    }
}

struct MyPageViewModel {
    let repository: MockDataRepository
    var section: MyPageSection = .myPosts

    /// プロフィールに出すニックネーム（認証が無いので固定）
    var userName: String {
        repository.currentUserName
    }

    /// 選んでいる一覧の投稿（新しい順）
    var posts: [Post] {
        posts(in: section)
    }

    /// 一覧ごとの投稿: 自分が公開した投稿 / スターした公開済みの投稿 / 自分の下書き
    func posts(in section: MyPageSection) -> [Post] {
        switch section {
        case .myPosts:
            repository.myPosts
        case .saved:
            repository.starredPosts
        case .drafts:
            repository.drafts
        }
    }

    /// 一覧ごとの件数（プロフィールの数字に出す）
    func count(in section: MyPageSection) -> Int {
        posts(in: section).count
    }

    /// 自分が公開した投稿がもらったいいねの合計
    var receivedLikeCount: Int {
        repository.myPosts.reduce(0) { $0 + $1.likeCount }
    }

    func toggleLike(_ post: Post) {
        repository.toggleLike(postID: post.id)
    }

    func toggleStar(_ post: Post) {
        repository.toggleStar(postID: post.id)
    }

    /// 下書きを削除する。公開済みの投稿や他人の投稿は消さない（下書きの一覧のスワイプからだけ呼ぶため）
    func deleteDraft(_ post: Post) {
        guard let stored = repository.post(id: post.id), stored.isDraft, repository.isMine(stored) else {
            return
        }
        repository.delete(postID: post.id)
    }

    /// 下書きの一覧に出すタイトル。空白だけなら nil（画面で「無題の下書き」と出す）
    static func draftTitle(of post: Post) -> String? {
        let title = post.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? nil : title
    }
}
