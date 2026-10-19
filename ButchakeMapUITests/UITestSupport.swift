//
//  UITestSupport.swift
//  ButchakeMapUITests
//
//  UI テストの共通の手順。表示言語に左右されないよう英語・米国のロケールで起動し、
//  要素はなるべく accessibilityIdentifier で探す（タブはタブバーの並び順で探す）
//

import XCTest

enum UITestTimeout {
    /// 画面の切り替え・アラートの表示を待つ秒数
    static let element: TimeInterval = 5
}

@MainActor
extension XCUIApplication {
    /// 英語・米国のロケールで、縦向きで起動したアプリ
    static func launchedInEnglish() -> XCUIApplication {
        // 起動テストは UI の構成ごとに走り、シミュレーターを横向きのまま残すことがある。
        // 縦向きを前提に要素を探すので、縦向きに戻してから起動する
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        return app
    }

    /// タブバーの index 番目（左から 0 始まり）のタブ
    func tab(at index: Int) -> XCUIElement {
        tabBars.firstMatch.buttons.element(boundBy: index)
    }

    /// identifier の要素（種類は問わない）
    func element(identifier: String) -> XCUIElement {
        descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// 要素がキーボード・タブバー・ナビゲーションバーに隠れずにタップできるか
    func isVisible(_ element: XCUIElement) -> Bool {
        guard element.exists, element.isHittable else {
            return false
        }
        let keyboard = keyboards.firstMatch
        return !keyboard.exists || element.frame.midY < keyboard.frame.minY
    }

    /// 要素が見えるまで画面を少しずつ上にスクロールする
    func scroll(to element: XCUIElement, maxSwipes: Int = 12, file: StaticString = #filePath, line: UInt = #line) {
        var swipes = 0
        while !isVisible(element) && swipes < maxSwipes {
            // キーボードが出ていても隠れない上半分で、勢いが付かないようゆっくり動かす
            let start = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45))
            let end = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
            start.press(forDuration: 0.05, thenDragTo: end)
            swipes += 1
        }
        XCTAssertTrue(isVisible(element), "スクロールしても見つからない: \(element)", file: file, line: line)
    }

    /// 候補のうち最初に現れた要素を返す。どれも現れなければ nil
    func firstAppearing(_ candidates: [XCUIElement], timeout: TimeInterval = UITestTimeout.element) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if let found = candidates.first(where: \.exists) {
                return found
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        } while Date() < deadline
        return nil
    }
}
