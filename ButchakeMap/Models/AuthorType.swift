//
//  AuthorType.swift
//  ButchakeMap
//

import Foundation

/// 投稿者の属性。rawValue は保存用の英字識別子で、画面には displayName を出す
nonisolated enum AuthorType: String, CaseIterable, Codable, Identifiable, Sendable {
    case local
    case repeater
    case traveler

    var id: Self { self }

    /// 画面に出す名前（Localizable.xcstrings で ja / en を持つ）
    var displayName: LocalizedStringResource {
        switch self {
        case .local:
            "Local"
        case .repeater:
            "Repeat Visitor"
        case .traveler:
            "Traveler"
        }
    }

    /// バッジに出す SF Symbol
    var symbolName: String {
        switch self {
        case .local:
            "house.fill"
        case .repeater:
            "arrow.triangle.2.circlepath"
        case .traveler:
            "airplane"
        }
    }
}
