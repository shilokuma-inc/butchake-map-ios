//
//  MainTabTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import Foundation
import Testing

struct MainTabTests {
    @Test
    func tabsAreOrderedHomeMapCreateSearchMyPage() {
        #expect(MainTab.allCases == [.home, .map, .create, .search, .myPage])
    }

    @Test
    func everyTabHasSymbol() {
        for tab in MainTab.allCases {
            #expect(!tab.symbolName.isEmpty, "\(tab) の SF Symbol が空")
        }
    }

    @Test(arguments: [
        (MainTab.home, "ホーム", "Home"),
        (MainTab.map, "マップ", "Map"),
        (MainTab.create, "投稿", "Post"),
        (MainTab.search, "検索", "Search"),
        (MainTab.myPage, "マイページ", "My Page")
    ])
    func tabTitleIsLocalized(tab: MainTab, japanese: String, english: String) {
        #expect(localized(tab.title, "ja") == japanese)
        #expect(localized(tab.title, "en") == english)
    }

    @Test
    func authorTypeAndCategoryNamesHaveJapanese() {
        for authorType in AuthorType.allCases {
            let resource = authorType.displayName
            #expect(localized(resource, "ja") != localized(resource, "en"), "\(authorType) の日本語が無い")
        }
        for category in Category.allCases {
            let resource = category.displayName
            #expect(localized(resource, "ja") != localized(resource, "en"), "\(category) の日本語が無い")
        }
    }

    private func localized(_ resource: LocalizedStringResource, _ language: String) -> String {
        var resource = resource
        resource.locale = Locale(identifier: language)
        return String(localized: resource)
    }
}
