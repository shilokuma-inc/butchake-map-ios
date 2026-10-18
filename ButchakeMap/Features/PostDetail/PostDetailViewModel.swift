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

    /// 表示する投稿。削除されていれば nil。下書きは公開前なので、ID で開かれても見つからない扱いにする
    var post: Post? {
        guard let post = repository.post(id: postID), !post.isDraft else {
            return nil
        }
        return post
    }

    /// 番号順のスポット
    var spots: [Spot] {
        post?.spots.sorted { $0.order < $1.order } ?? []
    }

    var isMine: Bool {
        post.map(repository.isMine) ?? false
    }

    /// 表示できない（削除済み・下書きの）投稿には何もしない
    func toggleLike() {
        guard post != nil else {
            return
        }
        repository.toggleLike(postID: postID)
    }

    func toggleStar() {
        guard post != nil else {
            return
        }
        repository.toggleStar(postID: postID)
    }
}
