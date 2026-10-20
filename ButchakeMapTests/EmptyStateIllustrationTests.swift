//
//  EmptyStateIllustrationTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import Testing
import UIKit

/// 空の状態の B-2 のイラスト（Assets.xcassets の EmptyPosts・EmptySearch）
struct EmptyStateIllustrationTests {
    /// 2 枚のイラストがアプリのバンドルから読め、元の SVG と同じ縦横比（320x240）になっている
    @Test(arguments: ["EmptyPosts", "EmptySearch"])
    func illustrationLoadsFromBundle(name: String) throws {
        let image = try #require(UIImage(named: name, in: .main, compatibleWith: nil), "\(name) が読めない")
        #expect(abs(image.size.width / image.size.height - 320.0 / 240.0) < 0.01)
    }

    /// ダークでもイラストが読め、ライトと同じ縦横比になっている（*-dark.svg は色だけが違う）
    @Test(arguments: ["EmptyPosts", "EmptySearch"])
    func darkIllustrationHasSameAspectRatio(name: String) throws {
        let dark = UITraitCollection(userInterfaceStyle: .dark)
        let image = try #require(UIImage(named: name, in: .main, compatibleWith: dark), "ダークの \(name) が読めない")
        #expect(abs(image.size.width / image.size.height - 320.0 / 240.0) < 0.01)
    }
}
