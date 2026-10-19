//
//  MainTabUITests.swift
//  ButchakeMapUITests
//

import XCTest

/// 5 つのタブを順に切り替え、それぞれの画面が出ることを確かめる
final class MainTabUITests: XCTestCase {
    /// 左から並べたタブと、開いたときのナビゲーションバーのタイトル（英語）
    private let tabs = [
        (name: "ホーム", navigationTitle: "Butchake Map"),
        (name: "マップ", navigationTitle: "Map"),
        (name: "投稿", navigationTitle: "New Post"),
        (name: "検索", navigationTitle: "Search"),
        (name: "マイページ", navigationTitle: "My Page")
    ]

    override func setUpWithError() throws {
        // UI テストでは失敗した時点で即座に止める
        continueAfterFailure = false
    }

    @MainActor
    func testSwitchingTabsShowsEachScreen() throws {
        let app = XCUIApplication.launchedInEnglish()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: UITestTimeout.element))
        XCTAssertEqual(tabBar.buttons.count, tabs.count)
        // 起動直後はホーム
        XCTAssertTrue(app.navigationBars[tabs[0].navigationTitle].waitForExistence(timeout: UITestTimeout.element))

        // 最後にホームへ戻れることも確かめる
        for index in Array(tabs.indices.dropFirst()) + [0] {
            app.tab(at: index).tap()
            XCTAssertTrue(
                app.navigationBars[tabs[index].navigationTitle].waitForExistence(timeout: UITestTimeout.element),
                "\(tabs[index].name)タブの画面が出ない"
            )
        }
    }
}
