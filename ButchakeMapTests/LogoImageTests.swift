//
//  LogoImageTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import Testing
import UIKit

/// B-2 のロゴ（Assets.xcassets の Logo。Tools/make_logo_svg.py で書き出した SVG）
struct LogoImageTests {
    /// ロゴがアプリのバンドルから読め、元の SVG の viewBox と同じ縦横比（528.82x131.34）になっている
    @Test
    func logoLoadsFromBundle() throws {
        let image = try #require(UIImage(named: "Logo", in: .main, compatibleWith: nil), "Logo が読めない")
        #expect(abs(image.size.width / image.size.height - 528.82 / 131.34) < 0.01)
    }
}
