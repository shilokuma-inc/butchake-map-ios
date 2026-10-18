//
//  PostCreateViewModel.swift
//  ButchakeMap
//
//  投稿の作成・編集フォームのロジック（入力チェック・スポットの位置の選択・下書き保存・公開）。
//  入力中の投稿は MockDataRepository に入れる前の一時的な状態なので、例外としてここにコピーを持つ。
//  保存・公開は Repository を経由し、ホーム・マイページなどの画面へすぐに反映される。
//

import CoreLocation
import Foundation
import MapKit
import Observation

@Observable
@MainActor
final class PostCreateViewModel {
    /// 文字数の上限
    enum Limit {
        static let title = 50
        static let city = 30
        static let spotName = 50
        static let spotAddress = 100
        static let spotRecommendation = 200
    }

    /// スポットの位置を選ぶ地図の初期表示の幅（度）
    enum LocationSpan {
        /// 既に位置を選んであるとき。周りの店や通りが見える程度まで寄せる
        static let selected = 0.01
        /// 都道府県だけ選んであるとき。県庁所在地の周りの市町村が見える程度
        static let prefecture = 1.0
    }

    /// 選んだ位置の緯度・経度を丸める小数点以下の桁数（約 0.1 m）
    static let coordinateFractionDigits = 6

    /// 入力欄
    enum Field: Hashable {
        case title
        case prefecture
        case city
        case spotName(order: Int)
        case spotAddress(order: Int)
        case spotRecommendation(order: Int)
    }

    /// 入力欄のエラー
    enum FieldError: Equatable {
        /// 公開に必要な項目が未入力
        case required
        /// 都道府県が未選択
        case unselected
        /// 文字数の上限を超えている
        case tooLong(limit: Int)

        var message: LocalizedStringResource {
            switch self {
            case .required:
                "Required"
            case .unselected:
                "Select a prefecture"
            case .tooLong(let limit):
                "Up to \(limit) characters"
            }
        }
    }

    /// 保存・公開した結果。画面でアラートにして知らせる
    enum Outcome: Equatable {
        case savedDraft
        case published
        case failed(PostSaveError)

        var title: LocalizedStringResource {
            switch self {
            case .savedDraft:
                "Draft saved"
            case .published:
                "Post published"
            case .failed:
                "Couldn't save"
            }
        }

        var message: LocalizedStringResource? {
            switch self {
            case .savedDraft:
                nil
            case .published:
                "Your post now appears on Home."
            case .failed(.notFound):
                "This post may have been deleted."
            case .failed(.alreadyPublished):
                "Published posts can't be saved as drafts."
            case .failed(.alreadyExists):
                "This post has already been saved."
            }
        }
    }

    private let repository: MockDataRepository

    /// 入力中の投稿
    var post: Post
    /// 新規作成か。false なら Repository にある投稿（下書き・公開済み）の編集
    private(set) var isNew: Bool
    /// 「公開する」を押した後だけ、必須項目の未入力をエラーとして出す
    private(set) var showsRequiredErrors = false
    /// 直近の保存・公開の結果。アラートを閉じたら nil に戻す
    var outcome: Outcome?

    /// - Parameter post: 編集する既存の投稿。nil なら自分の新しい下書きを作る
    init(post: Post?, repository: MockDataRepository) {
        self.repository = repository
        self.post = post ?? .newDraft(authorName: repository.currentUserName)
        isNew = post == nil
    }

    // MARK: - 入力チェック

    /// 画面に出す入力欄のエラー。文字数の上限は常に、必須項目は「公開する」を押した後だけ出す
    func error(for field: Field) -> FieldError? {
        Self.validate(post, requiresAll: showsRequiredErrors)[field]
    }

    /// 公開できる入力になっているか
    var canPublish: Bool {
        Self.validate(post, requiresAll: true).isEmpty
    }

    /// 「下書き保存」を出すか。公開済みの投稿は下書きに戻せないので出さない
    var showsSaveDraftButton: Bool {
        isNew || post.isDraft
    }

    /// 下書き保存できるか。何か入力してあり、文字数の上限を超えていないこと（未入力の項目があってもよい）
    var canSaveDraft: Bool {
        showsSaveDraftButton && hasInput && Self.validate(post, requiresAll: false).isEmpty
    }

    /// 入力欄ごとのエラーを返す。前後の空白・改行は除いて数える
    /// - Parameter requiresAll: true なら公開に必要な項目（住所・位置以外のすべて）の未入力もエラーにする
    static func validate(_ post: Post, requiresAll: Bool) -> [Field: FieldError] {
        var errors: [Field: FieldError] = [:]
        func check(_ text: String, _ field: Field, limit: Int, isRequired: Bool = true) {
            let count = text.trimmingCharacters(in: .whitespacesAndNewlines).count
            if count > limit {
                errors[field] = .tooLong(limit: limit)
            } else if requiresAll && isRequired && count == 0 {
                errors[field] = .required
            }
        }
        check(post.title, .title, limit: Limit.title)
        if requiresAll && Prefecture(rawValue: post.prefecture) == nil {
            errors[.prefecture] = .unselected
        }
        check(post.city, .city, limit: Limit.city)
        for spot in post.spots {
            check(spot.name, .spotName(order: spot.order), limit: Limit.spotName)
            check(spot.address, .spotAddress(order: spot.order), limit: Limit.spotAddress, isRequired: false)
            check(spot.recommendation, .spotRecommendation(order: spot.order), limit: Limit.spotRecommendation)
        }
        return errors
    }

    // MARK: - スポットの位置

    /// 位置を選ぶ地図の初期表示の範囲: 選んだ位置 → 選んだ都道府県の県庁所在地の辺り → 日本全体の順に決める
    func locationPickerRegion(forSpot order: Int) -> MKCoordinateRegion {
        Self.locationPickerRegion(for: post.spots.first { $0.order == order }, prefecture: post.prefecture)
    }

    /// スポットの位置を決める。緯度・経度は小数点以下 6 桁に丸める
    func setLocation(_ coordinate: CLLocationCoordinate2D, forSpot order: Int) {
        guard let index = post.spots.firstIndex(where: { $0.order == order }) else {
            return
        }
        post.spots[index].latitude = Self.rounded(coordinate.latitude)
        post.spots[index].longitude = Self.rounded(coordinate.longitude)
    }

    /// スポットの位置を解除する
    func clearLocation(forSpot order: Int) {
        guard let index = post.spots.firstIndex(where: { $0.order == order }) else {
            return
        }
        post.spots[index].latitude = nil
        post.spots[index].longitude = nil
    }

    static func locationPickerRegion(for spot: Spot?, prefecture: String) -> MKCoordinateRegion {
        if let coordinate = spot?.coordinate {
            return MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: LocationSpan.selected, longitudeDelta: LocationSpan.selected)
            )
        }
        if let center = Prefecture(rawValue: prefecture)?.capitalCoordinate {
            return MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: LocationSpan.prefecture, longitudeDelta: LocationSpan.prefecture)
            )
        }
        return PostMapViewModel.japanRegion
    }

    private static func rounded(_ degrees: Double) -> Double {
        let scale = pow(10, Double(coordinateFractionDigits))
        return (degrees * scale).rounded() / scale
    }

    // MARK: - 保存・公開

    /// 下書き保存し、成功したら新規ならフォームを新しい空の下書きに戻す
    func saveDraft() {
        guard canSaveDraft else {
            return
        }
        do {
            try repository.saveDraft(trimmedPost, isNew: isNew)
            finish(with: .savedDraft)
        } catch {
            outcome = .failed(error)
        }
    }

    /// 公開し、成功したら新規ならフォームを新しい空の下書きに戻す。必須項目が足りなければエラーを出して何もしない
    func publish() {
        showsRequiredErrors = true
        guard canPublish else {
            return
        }
        do {
            try repository.publish(trimmedPost, isNew: isNew)
            finish(with: .published)
        } catch {
            outcome = .failed(error)
        }
    }

    // MARK: - Private

    /// 文字を入れた項目か、位置を選んだスポットがあるか（カテゴリ・投稿者属性を選んだだけでは数えない）
    private var hasInput: Bool {
        let texts = [post.title, post.prefecture, post.city] + post.spots.flatMap { [$0.name, $0.address, $0.recommendation] }
        return texts.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            || post.spots.contains { $0.coordinate != nil }
    }

    /// 前後の空白・改行を除いた投稿
    private var trimmedPost: Post {
        var trimmed = post
        trimmed.title = post.title.trimmingCharacters(in: .whitespacesAndNewlines)
        trimmed.city = post.city.trimmingCharacters(in: .whitespacesAndNewlines)
        for index in trimmed.spots.indices {
            trimmed.spots[index].name = trimmed.spots[index].name.trimmingCharacters(in: .whitespacesAndNewlines)
            trimmed.spots[index].address = trimmed.spots[index].address.trimmingCharacters(in: .whitespacesAndNewlines)
            trimmed.spots[index].recommendation = trimmed.spots[index].recommendation.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return trimmed
    }

    /// 新規なら空の下書きに戻し、既存の投稿の編集なら保存した内容をフォームに残す
    private func finish(with outcome: Outcome) {
        self.outcome = outcome
        if isNew {
            post = .newDraft(authorName: repository.currentUserName)
        } else if let saved = repository.post(id: post.id) {
            post = saved
        }
        showsRequiredErrors = false
    }
}
