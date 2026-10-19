//
//  MainTab.swift
//  ButchakeMap
//

import Foundation

/// TabView のタブ（左から並べる順）
enum MainTab: String, CaseIterable, Identifiable {
    case home
    case map
    case create
    case search
    case myPage

    var id: Self { self }

    /// タブに出す名前（Localizable.xcstrings で ja / en を持つ）
    var title: LocalizedStringResource {
        switch self {
        case .home:
            "Home"
        case .map:
            "Map"
        case .create:
            "Post"
        case .search:
            "Search"
        case .myPage:
            "My Page"
        }
    }

    /// タブに出す SF Symbol
    var symbolName: String {
        switch self {
        case .home:
            "house"
        case .map:
            "map"
        case .create:
            "plus.circle"
        case .search:
            "magnifyingglass"
        case .myPage:
            "person.crop.circle"
        }
    }
}
