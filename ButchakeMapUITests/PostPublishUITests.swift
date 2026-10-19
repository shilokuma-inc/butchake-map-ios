//
//  PostPublishUITests.swift
//  ButchakeMapUITests
//

import XCTest

/// 投稿タブで全項目を入力して公開し、ホームのフィードに出ることを確かめる
final class PostPublishUITests: XCTestCase {
    private enum TabIndex {
        static let home = 0
        static let create = 2
    }

    /// 投稿タブのナビゲーションバーのタイトル（英語）
    private let formTitle = "New Post"

    override func setUpWithError() throws {
        // UI テストでは失敗した時点で即座に止める
        continueAfterFailure = false
    }

    @MainActor
    func testPublishingPostShowsItOnHomeFeed() throws {
        let app = XCUIApplication.launchedInEnglish()
        // 初期データと重ならないタイトル（キーボードの入力で崩れないよう ASCII にする）
        let title = "UI Test Big Three \(UUID().uuidString.prefix(6))"

        app.tab(at: TabIndex.create).tap()
        XCTAssertTrue(app.navigationBars[formTitle].waitForExistence(timeout: UITestTimeout.element))

        type(title, into: "postForm.title", in: app)
        try choosePrefecture("北海道", in: app)
        type("Sapporo", into: "postForm.city", in: app)
        choose("Hidden Gems", from: "postForm.category", in: app)
        choose("Local", from: "postForm.authorType", in: app)
        for order in 1...3 {
            type("Spot \(order) Place", into: "postForm.spot\(order).name", in: app)
            type("Honest comment \(order)", into: "postForm.spot\(order).comment", in: app)
        }

        let publish = app.element(identifier: "postForm.publish")
        app.scroll(to: publish)
        publish.tap()

        // 失敗のアラート（Couldn't save）で先に進まないよう、公開できたときのタイトルで待つ
        let alert = app.alerts["Post published"]
        XCTAssertTrue(alert.waitForExistence(timeout: UITestTimeout.element), "公開できたときのアラートが出ない")
        alert.buttons.firstMatch.tap()

        app.tab(at: TabIndex.home).tap()
        // フィードはカルーセルの下の LazyVStack にあり、画面の小さい機種ではスクロールするまで作られない
        let feed = app.element(identifier: "home.feed")
        var swipes = 0
        while !feed.waitForExistence(timeout: 1) && swipes < 6 {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(feed.exists, "ホームのフィードが無い")
        let post = feed.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", title)).firstMatch
        XCTAssertTrue(post.waitForExistence(timeout: UITestTimeout.element), "公開した投稿がホームのフィードに無い")
    }

    // MARK: - Private

    /// 入力欄までスクロールしてタップし、文字を入れる
    @MainActor
    private func type(_ text: String, into identifier: String, in app: XCUIApplication) {
        let field = app.element(identifier: identifier)
        app.scroll(to: field)
        field.tap()
        field.typeText(text)
    }

    /// 都道府県の一覧を開いて選ぶ（選ぶとフォームに戻る）
    @MainActor
    private func choosePrefecture(_ prefecture: String, in app: XCUIApplication) throws {
        let picker = app.element(identifier: "postForm.prefecture")
        app.scroll(to: picker)
        picker.tap()
        // 一覧の行はボタンとして出るが、出ない OS でも選べるよう文字も候補にする
        let option = try XCTUnwrap(
            app.firstAppearing([app.buttons[prefecture], app.staticTexts[prefecture]]),
            "都道府県の一覧に \(prefecture) が無い"
        )
        option.tap()
        XCTAssertTrue(app.navigationBars[formTitle].waitForExistence(timeout: UITestTimeout.element), "フォームに戻らない")
    }

    /// メニューの Picker を開いて選ぶ
    @MainActor
    private func choose(_ option: String, from identifier: String, in app: XCUIApplication) {
        let picker = app.element(identifier: identifier)
        app.scroll(to: picker)
        picker.tap()
        let item = app.buttons[option]
        XCTAssertTrue(item.waitForExistence(timeout: UITestTimeout.element), "メニューに \(option) が無い")
        item.tap()
    }
}
