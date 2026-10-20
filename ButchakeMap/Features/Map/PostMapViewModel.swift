//
//  PostMapViewModel.swift
//  ButchakeMap
//
//  マップに立てるピンの組み立て。投稿は持たず、毎回 MockDataRepository から引く（他の画面での変更・削除と同期させるため）
//

import CoreLocation
import Foundation
import MapKit

/// ピンの ID。投稿とスポットの組で 1 本のピンを表す。シートの表示に `.sheet(item:)` を使うため Identifiable にする
nonisolated struct MapPinID: Hashable, Identifiable, Sendable {
    let postID: Post.ID
    let spotID: Spot.ID

    var id: Self { self }
}

/// マップに立てる 1 本のピン（公開済みの投稿の 1 スポット）
nonisolated struct MapPin: Identifiable, Hashable, Sendable {
    let id: MapPinID
    let postTitle: String
    let category: Category
    /// 投稿の中での順番（1, 2, 3）
    let order: Int
    let spotName: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

/// 駅名標の帯に出す、路線の前後の駅（ピン）の番号。端の駅では片方が nil
nonisolated struct MapStationNeighbors: Equatable, Sendable {
    let previous: Int?
    let next: Int?

    static let none = Self(previous: nil, next: nil)
}

struct PostMapViewModel {
    /// 全ピンが入る範囲に足す余白の倍率
    static let fittingPaddingRatio = 1.4
    /// 範囲の最小の幅（度）。ピンが 1 本・近接しているときに寄りすぎないようにする
    static let minimumSpan = 0.02
    /// 範囲の幅の上限（度）。MKCoordinateSpan は緯度 180 度・経度 360 度を超えられない
    static let maximumLatitudeSpan = 180.0
    static let maximumLongitudeSpan = 360.0
    /// ピンが 1 本も無いときに出す日本全体の範囲
    static let japanRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.5, longitude: 137.5),
        span: MKCoordinateSpan(latitudeDelta: 22, longitudeDelta: 22)
    )

    let repository: MockDataRepository

    /// 公開済みの投稿（新しい順）のスポットを番号順に並べたピン。座標の無いスポットと下書きは除く
    var pins: [MapPin] {
        repository.publishedPosts.flatMap(Self.routePins(of:))
    }

    /// 選んだピンの投稿の路線: その投稿のピンを順位の順（1 → 2 → 3）に並べたもの。座標の無いスポットは飛ばす。
    /// 選んでいない・投稿が消えた（下書きに戻った）ときは空
    func routePins(for pinID: MapPinID?) -> [MapPin] {
        guard let pinID, let post = post(for: pinID) else {
            return []
        }
        return Self.routePins(of: post)
    }

    /// 路線（`MapPolyline`）に渡す座標の並び。`routePins(for:)` の順
    func routeCoordinates(for pinID: MapPinID?) -> [CLLocationCoordinate2D] {
        routePins(for: pinID).map(\.coordinate)
    }

    /// ピンの路線の前後の駅の番号（駅名標の帯の「◀ 1」「3 ▶」）。座標が無く路線に乗らないスポットは前後に数えない
    func neighbors(for pinID: MapPinID) -> MapStationNeighbors {
        let route = routePins(for: pinID)
        guard let index = route.firstIndex(where: { $0.id == pinID }) else {
            return .none
        }
        return MapStationNeighbors(
            previous: index > route.startIndex ? route[index - 1].order : nil,
            next: index + 1 < route.endIndex ? route[index + 1].order : nil
        )
    }

    /// 初期表示の範囲: 全ピンが入る範囲（ピンが無ければ日本全体）
    var initialRegion: MKCoordinateRegion {
        Self.region(fitting: pins.map(\.coordinate))
    }

    /// ピンの投稿。削除・下書きに戻された投稿は nil
    func post(for pinID: MapPinID) -> Post? {
        guard let post = repository.post(id: pinID.postID), !post.isDraft else {
            return nil
        }
        return post
    }

    /// ピンのスポット。投稿が無い・スポットが消えていれば nil
    func spot(for pinID: MapPinID) -> Spot? {
        post(for: pinID)?.spots.first { $0.id == pinID.spotID }
    }

    func toggleLike(postID: Post.ID) {
        repository.toggleLike(postID: postID)
    }

    func toggleStar(postID: Post.ID) {
        repository.toggleStar(postID: postID)
    }

    /// 座標をすべて含む範囲。空なら日本全体。幅は最小値と上限の間に収める
    static func region(fitting coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        guard let minLatitude = latitudes.min(), let maxLatitude = latitudes.max(),
              let minLongitude = longitudes.min(), let maxLongitude = longitudes.max() else {
            return japanRegion
        }
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLatitude + maxLatitude) / 2,
                longitude: (minLongitude + maxLongitude) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: min(max((maxLatitude - minLatitude) * fittingPaddingRatio, minimumSpan), maximumLatitudeSpan),
                longitudeDelta: min(max((maxLongitude - minLongitude) * fittingPaddingRatio, minimumSpan), maximumLongitudeSpan)
            )
        )
    }

    /// 投稿のスポットを順位の順に並べたピン（座標の無いスポットは除く）
    private static func routePins(of post: Post) -> [MapPin] {
        post.spots.sorted { $0.order < $1.order }.compactMap { spot in
            pin(post: post, spot: spot)
        }
    }

    private static func pin(post: Post, spot: Spot) -> MapPin? {
        guard let coordinate = spot.coordinate else {
            return nil
        }
        return MapPin(
            id: MapPinID(postID: post.id, spotID: spot.id),
            postTitle: post.title,
            category: post.category,
            order: spot.order,
            spotName: spot.name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }
}
