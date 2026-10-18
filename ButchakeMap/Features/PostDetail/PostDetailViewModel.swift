//
//  PostDetailViewModel.swift
//  ButchakeMap
//
//  投稿詳細のロジック。投稿は ID だけ持ち、毎回 MockDataRepository から引く（他の画面での変更・削除と同期させるため）
//

import Foundation

struct PostDetailViewModel {
    let repository: MockDataRepository
    let postID: Post.ID

    /// 表示する投稿。削除されていれば nil
    var post: Post? {
        repository.post(id: postID)
    }

    /// 番号順のスポット
    var spots: [Spot] {
        post?.spots.sorted { $0.order < $1.order } ?? []
    }

    var isMine: Bool {
        post.map(repository.isMine) ?? false
    }

    func toggleLike() {
        repository.toggleLike(postID: postID)
    }

    func toggleStar() {
        repository.toggleStar(postID: postID)
    }
}
