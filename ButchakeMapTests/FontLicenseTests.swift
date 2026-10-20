//
//  FontLicenseTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import Testing

/// 設定から開く書体のライセンス
struct FontLicenseTests {
    /// 3 つの書体のライセンス文がバンドルから読め、SIL Open Font License 1.1 の全文になっている
    @Test(arguments: FontLicense.allCases)
    func licenseTextLoadsFromBundle(font: FontLicense) throws {
        let text = try #require(font.licenseText(), "\(font.licenseFileName).txt が読めない")
        #expect(text.contains("SIL OPEN FONT LICENSE Version 1.1"))
        // 書体ごとの著作権の行（OFL の本文にも「Copyright」はあるので、ファイルの 1 行目で確かめる）
        #expect(text.hasPrefix("Copyright "))
        // 全文（前文・許可・条件・終了・免責）が入っている
        for heading in ["PREAMBLE", "PERMISSION & CONDITIONS", "TERMINATION", "DISCLAIMER"] {
            #expect(text.contains(heading), "\(heading) が無い")
        }
    }

    /// 表示用の文は、段落の中の改行を空白にし、空行・区切り線・見出しの改行は残す
    @Test
    func reflowedJoinsLinesInsideParagraphs() {
        // 「worldwide」の行の末尾には空白を置く（原文の「embedded, 」のような行末の空白は取ってつなぐ）
        let text = """
            Copyright 2020 The Example Authors

            ---------
            SIL OPEN FONT LICENSE Version 1.1
            ---------

            PREAMBLE
            The goals of the Open Font License (OFL) are to stimulate worldwide \("")
            development of collaborative font projects.

            DISCLAIMER
            THE FONT SOFTWARE IS PROVIDED "AS IS",
            WITHOUT WARRANTY OF ANY KIND.
            """
        let expected = """
            Copyright 2020 The Example Authors

            ---------
            SIL OPEN FONT LICENSE Version 1.1
            ---------

            PREAMBLE
            The goals of the Open Font License (OFL) are to stimulate worldwide development of collaborative font projects.

            DISCLAIMER
            THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.
            """
        #expect(FontLicense.reflowed(text) == expected)
    }

    /// 同梱のライセンス文を表示用にしても、語は 1 つも増減せず、見出しは行の頭に残る
    @Test(arguments: FontLicense.allCases)
    func reflowedKeepsLicenseWords(font: FontLicense) throws {
        let text = try #require(font.licenseText())
        let reflowed = FontLicense.reflowed(text)
        let words: (String) -> [Substring] = { $0.split(whereSeparator: \.isWhitespace) }
        #expect(words(reflowed) == words(text))
        #expect(reflowed.components(separatedBy: "\n").count < text.components(separatedBy: "\n").count)
        for heading in ["PREAMBLE", "DEFINITIONS", "PERMISSION & CONDITIONS", "TERMINATION", "DISCLAIMER"] {
            #expect(reflowed.contains("\n\(heading)\n"), "\(heading) が見出しの行で残っていない")
        }
        #expect(reflowed.contains("\nSIL OPEN FONT LICENSE Version 1.1 - 26 February 2007\n"))
    }

    /// 書体の名前とライセンス文のファイルが重ならない
    @Test
    func familyNamesAndFilesAreUnique() {
        #expect(Set(FontLicense.allCases.map(\.familyName)).count == FontLicense.allCases.count)
        #expect(Set(FontLicense.allCases.map(\.licenseFileName)).count == FontLicense.allCases.count)
    }
}
