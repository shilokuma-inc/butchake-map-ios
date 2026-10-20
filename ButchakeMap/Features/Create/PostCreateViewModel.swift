//
//  PostCreateViewModel.swift
//  ButchakeMap
//
//  投稿の作成・編集フォームのロジック（入力チェック・スポットの位置と写真の選択・下書き保存・公開）。
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
            case .failed(.notMine):
                "You can only edit your own posts."
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
    /// 新しく公開したとき（新規・下書きの公開）に台紙へ押すスタンプ。結果のアラートを閉じたら nil に戻す。
    /// 公開済みの投稿の編集は新しいスタンプにならないので作らない
    private(set) var publishStamp: PublishStamp?
    /// スタンプを押す動きの途中か。途中は結果のアラートを出さない
    private(set) var isPressingStamp = false
    /// 写真を読み込み・縮小中のスポットの order。読み込み中に保存・公開すると選んだ写真が落ちるので、空になるまで保存・公開させない
    private(set) var loadingPhotoSpots: Set<Int> = []
    /// 直近の写真の読み込みに失敗したスポットの order
    private(set) var failedPhotoSpots: Set<Int> = []
    /// スポットごとの写真の読み込み。フォームの行が画面外に出ても取り消されないよう、View ではなく ViewModel に持つ
    @ObservationIgnored private var photoLoadTasks: [Int: Task<Void, Never>] = [:]

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

    /// 写真を読み込み中か。読み込み中は「公開する」「下書き保存」を押せない
    var isLoadingPhoto: Bool {
        !loadingPhotoSpots.isEmpty
    }

    /// 「下書き保存」を出すか。公開済みの投稿は下書きに戻せないので出さない
    var showsSaveDraftButton: Bool {
        isNew || post.isDraft
    }

    /// 下書き保存できるか。何か入力してあり、文字数の上限を超えていないこと（未入力の項目があってもよい）
    var canSaveDraft: Bool {
        showsSaveDraftButton && !isLoadingPhoto && hasInput && Self.validate(post, requiresAll: false).isEmpty
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

    /// 位置を選ぶ地図を一度動かすまで確定させないか。選んだ位置も都道府県も無く日本全体を出すときは、
    /// 地図の中心が海の上なので、そのまま確定すると意味の無い位置になる
    func locationPickerRequiresMove(forSpot order: Int) -> Bool {
        Self.locationPickerRequiresMove(for: post.spots.first { $0.order == order }, prefecture: post.prefecture)
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

    static func locationPickerRequiresMove(for spot: Spot?, prefecture: String) -> Bool {
        spot?.coordinate == nil && Prefecture(rawValue: prefecture) == nil
    }

    private static func rounded(_ degrees: Double) -> Double {
        let scale = pow(10, Double(coordinateFractionDigits))
        return (degrees * scale).rounded() / scale
    }

    // MARK: - スポットの写真

    /// スポットの写真を決める（選び直しも同じ）。data は SpotPhotoProcessor で縮小・JPEG 圧縮したもの
    func setPhoto(_ data: Data, forSpot order: Int) {
        guard let index = post.spots.firstIndex(where: { $0.order == order }) else {
            return
        }
        post.spots[index].photoData = data
    }

    /// スポットの写真を読み込んで決める。load は縮小・JPEG 圧縮したデータを返す（失敗したら nil）。
    /// 読み込み中に選び直したら前の読み込みは取り消し、後から選んだ写真だけを残す。失敗したら前の写真は残す
    func loadPhoto(forSpot order: Int, using load: @escaping @Sendable () async -> Data?) {
        guard post.spots.contains(where: { $0.order == order }) else {
            return
        }
        photoLoadTasks[order]?.cancel()
        loadingPhotoSpots.insert(order)
        failedPhotoSpots.remove(order)
        photoLoadTasks[order] = Task {
            let data = await load()
            guard !Task.isCancelled else {
                return
            }
            photoLoadTasks[order] = nil
            loadingPhotoSpots.remove(order)
            if let data {
                setPhoto(data, forSpot: order)
            } else {
                failedPhotoSpots.insert(order)
            }
        }
    }

    /// 読み込み中の写真がすべて終わるまで待つ（テスト用）
    func waitForPhotoLoads() async {
        for task in photoLoadTasks.values {
            await task.value
        }
    }

    /// スポットの写真を削除する。読み込み中ならその読み込みも取り消す
    func removePhoto(forSpot order: Int) {
        guard let index = post.spots.firstIndex(where: { $0.order == order }) else {
            return
        }
        cancelPhotoLoad(forSpot: order)
        failedPhotoSpots.remove(order)
        post.spots[index].photoData = nil
    }

    private func cancelPhotoLoad(forSpot order: Int) {
        photoLoadTasks[order]?.cancel()
        photoLoadTasks[order] = nil
        loadingPhotoSpots.remove(order)
    }

    // MARK: - 保存・公開

    /// 結果のアラートを出すか。公開のスタンプを押す動きが終わるまでは出さない
    var showsOutcomeAlert: Bool {
        outcome != nil && !isPressingStamp
    }

    /// スタンプを押す動きが終わった。結果のアラートを出す
    func finishPressingStamp() {
        isPressingStamp = false
    }

    /// 結果のアラートを閉じる。スタンプも片付け、閉じた結果を返す
    func dismissOutcome() -> Outcome? {
        let dismissed = outcome
        outcome = nil
        publishStamp = nil
        isPressingStamp = false
        return dismissed
    }

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
        guard !isLoadingPhoto else {
            return
        }
        showsRequiredErrors = true
        guard canPublish else {
            return
        }
        // 公開する前に、新しく公開するのか（公開済みの投稿の編集ではないか）を決めておく
        let isNewPublication = isNew || post.isDraft
        do {
            try repository.publish(trimmedPost, isNew: isNew)
            if isNewPublication, let published = repository.post(id: post.id) {
                publishStamp = PublishStamp.make(book: HomeViewModel(repository: repository).stampBook(), published: published)
                isPressingStamp = publishStamp != nil
            }
            finish(with: .published)
        } catch {
            outcome = .failed(error)
        }
    }

    // MARK: - Private

    /// 文字を入れた項目か、位置・写真を選んだスポットがあるか（カテゴリ・投稿者属性を選んだだけでは数えない）
    private var hasInput: Bool {
        let texts = [post.title, post.prefecture, post.city] + post.spots.flatMap { [$0.name, $0.address, $0.recommendation] }
        return texts.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            || post.spots.contains { $0.coordinate != nil || $0.photoData != nil }
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
            failedPhotoSpots = []
        } else if let saved = repository.post(id: post.id) {
            post = saved
        }
        showsRequiredErrors = false
    }
}
