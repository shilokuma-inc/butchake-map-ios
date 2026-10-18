//
//  Category.swift
//  ButchakeMap
//

import Foundation

/// 投稿のカテゴリ。rawValue は保存用の英字識別子で、画面には displayName を出す
nonisolated enum Category: String, CaseIterable, Codable, Identifiable, Sendable {
    case gourmet
    case scenery
    case disappointment
    case hiddenGem
    case other

    var id: Self { self }

    /// 画面に出す名前（Localizable.xcstrings で ja / en を持つ）
    var displayName: LocalizedStringResource {
        switch self {
        case .gourmet:
            "Gourmet"
        case .scenery:
            "Scenery & Sightseeing"
        case .disappointment:
            "Big Three Letdowns"
        case .hiddenGem:
            "Hidden Gems"
        case .other:
            "Other"
        }
    }

    /// 写真の無いスポットに出すプレースホルダーの SF Symbol
    var symbolName: String {
        switch self {
        case .gourmet:
            "fork.knife"
        case .scenery:
            "mountain.2"
        case .disappointment:
            "face.dashed"
        case .hiddenGem:
            "sparkle.magnifyingglass"
        case .other:
            "mappin.and.ellipse"
        }
    }
}
