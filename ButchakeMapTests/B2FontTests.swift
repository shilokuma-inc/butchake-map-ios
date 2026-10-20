//
//  B2FontTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import CoreText
import Foundation
import Testing
import UIKit

/// B-2 の同梱の書体（ButchakeMap/Resources/Fonts）
struct B2FontTests {
    /// 4 つの書体が PostScript 名で読める（Info.plist の UIAppFonts への登録漏れ・ファイルの入れ忘れを見つける）
    @Test(arguments: B2Font.Name.all)
    func fontLoadsByPostScriptName(name: String) {
        #expect(UIFont(name: name, size: 17) != nil, "\(name) を読めない")
    }

    /// サブセットのスタンプの書体が、使う文字の一覧（Tools/stamp_font_glyphs.txt）の文字をすべて持つ
    @Test
    func stampFontHasAllGlyphsInGlyphList() throws {
        let glyphList = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Tools/stamp_font_glyphs.txt")
        let text = try String(contentsOf: glyphList, encoding: .utf8)
            .filter { !$0.isWhitespace }
        #expect(!text.isEmpty)
        for character in text {
            #expect(B2Font.stampFontCovers(String(character)), "スタンプの書体に「\(character)」が無い")
        }
    }

    /// コードでスタンプの書体に出す決まった文字が、すべてサブセットにある
    @Test(arguments: B2Font.stampStrings)
    func stampFontCoversStampStrings(text: String) {
        #expect(B2Font.stampFontCovers(text), "スタンプの書体に「\(text)」の文字が無い。Tools/stamp_font_glyphs.txt に足してサブセットを作り直す")
    }

    /// スタンプの日付（M.d）の文字もサブセットにある
    @Test
    func stampFontCoversDates() {
        #expect(B2Font.stampFontCovers("10.18"))
        #expect(B2Font.stampFontCovers("2026/1/9"))
    }

    /// サブセットに無い文字（市区町村の名前など）は false になり、スタンプの部品が別の書体を選べる
    @Test
    func stampFontDoesNotCoverOtherCharacters() {
        #expect(!B2Font.stampFontCovers("金沢"))
        #expect(!B2Font.stampFontCovers("札幌市"))
    }

    /// ナビゲーションのタイトルの書体が BIZ UDPゴシック Bold になり、インラインのタイトルは文字の大きさの設定によらず 17pt
    @Test
    func navigationTitleFontsAreGothicBold() {
        #expect(UIFont.b2InlineNavigationTitle.fontName == B2Font.Name.gothicBold)
        #expect(UIFont.b2InlineNavigationTitle.pointSize == 17)
        #expect(UIFont.b2LargeNavigationTitle.fontName == B2Font.Name.gothicBold)
    }

    /// ナビゲーションバーの外観（通常・スクロールの端）にタイトルの書体が入る
    @Test
    func navigationBarAppearanceUsesGothicBold() throws {
        B2NavigationBarAppearance.apply()
        let proxy = UINavigationBar.appearance()
        for appearance in [proxy.standardAppearance, try #require(proxy.scrollEdgeAppearance)] {
            let title = try #require(appearance.titleTextAttributes[.font] as? UIFont)
            let largeTitle = try #require(appearance.largeTitleTextAttributes[.font] as? UIFont)
            #expect(title.fontName == B2Font.Name.gothicBold)
            #expect(largeTitle.fontName == B2Font.Name.gothicBold)
        }
    }

    /// スタンプの文字列にスペースを含めても、スタンプの書体で出せる
    @Test
    func stampFontCoversSpace() {
        #expect(B2Font.stampFontCovers("済 10.18"))
    }
}
