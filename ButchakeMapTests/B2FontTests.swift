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
        #expect(!B2Font.stampFontCovers("済み"))
    }

    /// ナビゲーションのタイトルの書体が BIZ UDPゴシック Bold になる
    @Test
    func navigationTitleFontIsGothicBold() {
        let font = UIFont.b2NavigationTitle(size: 17, textStyle: .headline)
        #expect(font.fontName == B2Font.Name.gothicBold)
    }
}
