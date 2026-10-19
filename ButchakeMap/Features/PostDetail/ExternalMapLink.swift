//
//  ExternalMapLink.swift
//  ButchakeMap
//
//  スポットを外部のマップアプリで開く URL の組み立て。
//  座標があれば座標で、無ければ「スポット名 + 住所」の検索で開く
//

import CoreLocation
import Foundation

/// スポットを開ける外部のマップアプリ
nonisolated enum ExternalMapApp: String, CaseIterable, Identifiable, Sendable {
    case appleMaps
    case googleMaps

    var id: Self { self }

    var displayName: LocalizedStringResource {
        switch self {
        case .appleMaps:
            "Apple Maps"
        case .googleMaps:
            "Google Maps"
        }
    }

    /// インストールされているか canOpenURL で確かめる URL。Apple マップは常にあるものとして nil
    var availabilityCheckURL: URL? {
        switch self {
        case .appleMaps:
            nil
        case .googleMaps:
            URL(string: "comgooglemaps://")
        }
    }
}

nonisolated enum ExternalMapLink {
    /// 端末で使えるマップアプリ（Apple マップが先頭）
    /// - Parameter canOpen: `UIApplication.shared.canOpenURL` を渡す。テストでは差し替える
    static func availableApps(canOpen: (URL) -> Bool) -> [ExternalMapApp] {
        ExternalMapApp.allCases.filter { app in
            app.availabilityCheckURL.map(canOpen) ?? true
        }
    }

    /// スポットを指定のアプリで開く URL。座標も名前も住所も無ければ nil（ボタンを出さない）
    static func url(for spot: Spot, in app: ExternalMapApp) -> URL? {
        let query = searchQuery(for: spot)
        let coordinate = spot.coordinate.map { "\($0.latitude),\($0.longitude)" }
        let items: [(String, String)]
        switch (app, coordinate) {
        case let (.appleMaps, coordinate?):
            // ll でピンの位置を決め、q はピンの名前として出す
            items = [("ll", coordinate)] + (query.isEmpty ? [] : [("q", query)])
        case let (.googleMaps, coordinate?):
            // 名前で検索すると別の店に当たることがあるので、座標を検索語にして位置を優先する
            items = [("q", coordinate), ("center", coordinate)]
        case (_, nil):
            guard !query.isEmpty else {
                return nil
            }
            items = [("q", query)]
        }
        return makeURL(base: baseURL(for: app), items: items)
    }

    /// 座標が無いときの検索語（スポット名と住所を空白でつなぐ）
    static func searchQuery(for spot: Spot) -> String {
        [spot.name, spot.address]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func baseURL(for app: ExternalMapApp) -> String {
        switch app {
        case .appleMaps:
            "https://maps.apple.com/"
        case .googleMaps:
            "comgooglemaps://"
        }
    }

    /// クエリの値で区切りや空白と解釈される文字（& = + ? # など）もエンコードする
    private static let queryValueAllowed: CharacterSet = {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=+?#/")
        return allowed
    }()

    private static func makeURL(base: String, items: [(String, String)]) -> URL? {
        let query = items
            .compactMap { name, value in
                value.addingPercentEncoding(withAllowedCharacters: queryValueAllowed).map { "\(name)=\($0)" }
            }
            .joined(separator: "&")
        return URL(string: "\(base)?\(query)")
    }
}
