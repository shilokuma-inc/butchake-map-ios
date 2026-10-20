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
        post.map(Self.orderedSpots) ?? []
    }

    /// 投稿のスポットを番号順に並べる
    static func orderedSpots(of post: Post) -> [Spot] {
        post.spots.sorted { $0.order < $1.order }
    }

    /// 投稿詳細の頭の、都市の駅名標に出す文字（Discussion #77 の Q6）
    struct StationSignText: Equatable {
        /// 大きな文字。市区町村、空なら都道府県
        let name: String
        /// 英字の行。都道府県のローマ字（47 都道府県に無い名前なら nil）
        let english: String?
    }

    static func stationSignText(of post: Post) -> StationSignText {
        let city = post.city.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefecture = post.prefecture.trimmingCharacters(in: .whitespacesAndNewlines)
        return StationSignText(
            name: city.isEmpty ? prefecture : city,
            english: Prefecture(rawValue: prefecture)?.romanizedName
        )
    }

    /// 駅のスタンプの上の日付（投稿日の「M.d」。端末のカレンダー）
    static func stampDate(of post: Post, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.month, .day], from: post.createdAt)
        return "\(components.month ?? 0).\(components.day ?? 0)"
    }

    /// 駅のスタンプの下の地名（市区町村、空なら都道府県）
    static func stampPlace(of post: Post) -> String {
        stationSignText(of: post).name
    }

    var isMine: Bool {
        post.map(repository.isMine) ?? false
    }

    /// 編集・削除のメニューを出すか。自分の公開済みの投稿だけ
    var canEditOrDelete: Bool {
        isMine
    }

    /// 編集で作成画面に開く投稿。他人の投稿・表示できない投稿は nil
    var editablePost: Post? {
        canEditOrDelete ? post : nil
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

    /// 自分の投稿を削除する。他人の投稿・表示できない投稿は消さない
    /// - Returns: 削除したか（削除したら画面で詳細を閉じる）
    @discardableResult
    func delete() -> Bool {
        guard canEditOrDelete else {
            return false
        }
        return repository.delete(postID: postID)
    }

    /// 編集の結果のアラートを閉じた後に作成画面を閉じて詳細に戻るか。下書きの編集と同じく、公開したら閉じる
    /// （公開済みの投稿の編集では下書き保存は出ない）
    static func closesEditor(after outcome: PostCreateViewModel.Outcome) -> Bool {
        DraftEditViewModel.closesForm(after: outcome)
    }
}
