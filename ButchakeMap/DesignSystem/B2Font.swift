//
//  B2Font.swift
//  ButchakeMap
//

import SwiftUI
import UIKit

/// B-2「駅のスタンプラリー」の書体（ButchakeMap/Resources/Fonts。Info.plist の UIAppFonts に登録している）
///
/// - BIZ UDPゴシック: 本文・見出し・駅名標
/// - DotGothic16: きっぷ・英字・数字（発車標・件数・日付）
/// - Kaisei Decol: スタンプの文字。スタンプに出す文字だけにサブセット化している（Tools/subset_stamp_font.sh）
///
/// どれも `Font.custom(_:size:relativeTo:)` で、Dynamic Type の文字の大きさに合わせて大きくなる
enum B2Font {
    /// 書体の PostScript 名（書体のファイルの name テーブルの値）
    enum Name {
        nonisolated static let gothicRegular = "BIZUDPGothic-Regular"
        nonisolated static let gothicBold = "BIZUDPGothic-Bold"
        nonisolated static let ticket = "DotGothic16-Regular"
        nonisolated static let stamp = "KaiseiDecol-Bold"

        nonisolated static let all = [gothicRegular, gothicBold, ticket, stamp]
    }

    /// スタンプの書体で出す決まった文字（「済」・公開のスタンプ）。
    /// スタンプの書体はサブセットなので、ここに足した文字は Tools/stamp_font_glyphs.txt にも足してサブセットを作り直す
    nonisolated static let stampStrings = ["済", "公開", "公開しました"]

    /// 文字がすべてスタンプの書体（サブセット）にあるか。無い文字（市区町村の名前など）は代わりの書体で黙って出てしまうので、
    /// スタンプの部品は false のとき別の書体（BIZ UDPゴシック Bold）を選ぶ
    static func stampFontCovers(_ text: String) -> Bool {
        guard let font = UIFont(name: Name.stamp, size: 17) else {
            return false
        }
        let characters = Array(text.utf16)
        guard !characters.isEmpty else {
            return true
        }
        var glyphs = [CGGlyph](repeating: 0, count: characters.count)
        return CTFontGetGlyphsForCharacters(font as CTFont, characters, &glyphs, characters.count)
    }
}

extension Font {
    /// 本文（BIZ UDPゴシック Regular 17pt。body に合わせて大きくなる）
    static let b2Body = Font.custom(B2Font.Name.gothicRegular, size: 17, relativeTo: .body)

    /// 見出し（BIZ UDPゴシック Bold）
    static func b2Heading(size: CGFloat = 17, relativeTo textStyle: Font.TextStyle = .headline) -> Font {
        .custom(B2Font.Name.gothicBold, size: size, relativeTo: textStyle)
    }

    /// 本文の書体で大きさだけ変える（BIZ UDPゴシック Regular）
    static func b2Text(size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        .custom(B2Font.Name.gothicRegular, size: size, relativeTo: textStyle)
    }

    /// きっぷ・英字・数字（DotGothic16）
    static func b2Ticket(size: CGFloat = 13, relativeTo textStyle: Font.TextStyle = .footnote) -> Font {
        .custom(B2Font.Name.ticket, size: size, relativeTo: textStyle)
    }

    /// スタンプの文字（Kaisei Decol Bold。サブセットにある文字だけに使う。B2Font.stampFontCovers(_:) で確かめる）
    static func b2Stamp(size: CGFloat = 16, relativeTo textStyle: Font.TextStyle = .callout) -> Font {
        .custom(B2Font.Name.stamp, size: size, relativeTo: textStyle)
    }
}

extension UIFont {
    /// ナビゲーションバーのタイトルの書体（BIZ UDPゴシック Bold を、文字の大きさの設定に合わせた大きさにする）
    static func b2NavigationTitle(size: CGFloat, textStyle: UIFont.TextStyle) -> UIFont {
        let base = UIFont(name: B2Font.Name.gothicBold, size: size) ?? .systemFont(ofSize: size, weight: .bold)
        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: base)
    }
}

enum B2NavigationBarAppearance {
    /// ナビゲーションバーのタイトル（通常と大きなタイトル）を BIZ UDPゴシック Bold にする。
    /// UIFontMetrics の大きさは作ったときの設定で決まるので、アプリの起動時に 1 回呼ぶ
    static func apply() {
        let appearance = UINavigationBar.appearance()
        appearance.titleTextAttributes = [.font: UIFont.b2NavigationTitle(size: 17, textStyle: .headline)]
        appearance.largeTitleTextAttributes = [.font: UIFont.b2NavigationTitle(size: 34, textStyle: .largeTitle)]
    }
}

#Preview("書体の見本") {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            Text(verbatim: "金沢 KANAZAWA ぶっちゃけ線")
                .font(.b2Heading(size: 28, relativeTo: .title))
            Text(verbatim: "ランチのコスパと鮮度は県内トップクラス。The quick brown fox jumps over the lazy dog.")
                .font(.b2Body)
            Text(verbatim: "2026/10/18 石川県 金沢市 ゆき No.0128")
                .font(.b2Ticket(size: 17, relativeTo: .body))
                .foregroundStyle(Color.brandPrimary)
            Text(verbatim: "済 公開 10.18")
                .font(.b2Stamp(size: 26, relativeTo: .title2))
                .foregroundStyle(Color.brandPrimary)
        }
        .padding()
    }
}

#Preview("書体の見本（大きな文字）") {
    VStack(alignment: .leading, spacing: 16) {
        Text(verbatim: "金沢 KANAZAWA")
            .font(.b2Heading(size: 28, relativeTo: .title))
        Text(verbatim: "ランチのコスパと鮮度は県内トップクラス。")
            .font(.b2Body)
        Text(verbatim: "2026/10/18 No.0128")
            .font(.b2Ticket(size: 17, relativeTo: .body))
        Text(verbatim: "済 10.18")
            .font(.b2Stamp(size: 26, relativeTo: .title2))
    }
    .padding()
    .environment(\.dynamicTypeSize, .accessibility5)
}
