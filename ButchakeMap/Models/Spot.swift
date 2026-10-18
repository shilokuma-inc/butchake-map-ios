//
//  Spot.swift
//  ButchakeMap
//

import CoreLocation
import Foundation

/// 投稿の 1 スポット（1 投稿につき 3 つ固定）
nonisolated struct Spot: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    /// 投稿の中での順番（1, 2, 3）
    var order: Int
    var name: String
    var address: String
    var latitude: Double?
    var longitude: Double?
    /// ぶっちゃけ推しコメント
    var recommendation: String
    /// 写真の URL（任意）。モック投稿では nil にし、カテゴリのプレースホルダーを出す
    var photoUrl: String?

    /// 緯度・経度が両方あるときだけ座標を返す
    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// 入力前の空のスポット
    static func empty(order: Int) -> Self {
        Self(order: order, name: "", address: "", recommendation: "")
    }
}
