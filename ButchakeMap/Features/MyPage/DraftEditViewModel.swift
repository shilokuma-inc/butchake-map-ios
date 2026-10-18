//
//  DraftEditViewModel.swift
//  ButchakeMap
//
//  マイページの下書きを作成画面で開いて編集するときのロジック（開く対象と、保存・公開の後に画面を閉じるか）。
//  入力・保存・公開そのものは PostCreateViewModel が受け持つ
//

import Foundation

/// 下書きの編集画面への遷移先。投稿そのものではなく ID を渡し、開くときに Repository から引く
struct DraftDestination: Hashable {
    let postID: Post.ID
}

struct DraftEditViewModel {
    /// 開いた時点の下書き。削除された・公開された・他人の投稿なら nil（作成画面では開かない）。
    /// 保存・公開でフォームが作り直されないよう、開いた時点の値を持ち続ける
    let draft: Post?

    init(postID: Post.ID, repository: MockDataRepository) {
        guard let post = repository.post(id: postID), post.isDraft, repository.isMine(post) else {
            draft = nil
            return
        }
        draft = post
    }

    /// 結果のアラートを閉じた後に編集画面を閉じてマイページに戻るか。
    /// 公開したら下書きではなくなるので閉じ、下書き保存は続けて編集できるよう残す。
    /// 編集中に削除された・他人の投稿で保存・公開できなくなったときは、フォームから抜けられるよう閉じる
    static func closesForm(after outcome: PostCreateViewModel.Outcome) -> Bool {
        switch outcome {
        case .published, .failed(.notFound), .failed(.notMine):
            true
        case .savedDraft, .failed(.alreadyPublished), .failed(.alreadyExists):
            false
        }
    }
}
