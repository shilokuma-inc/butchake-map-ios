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
        guard let font = stampFont else {
            return false
        }
        let characters = Array(text.utf16)
        guard !characters.isEmpty else {
            return true
        }
        var glyphs = [CGGlyph](repeating: 0, count: characters.count)
        return CTFontGetGlyphsForCharacters(font, characters, &glyphs, characters.count)
    }

    /// 文字があるかを調べるためのスタンプの書体（部品の body から何度も呼ばれるので 1 回だけ作る）
    private static let stampFont: CTFont? = UIFont(name: Name.stamp, size: 17).map { $0 as CTFont }
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
    /// ナビゲーションバーの通常（インライン）のタイトルの書体（BIZ UDPゴシック Bold 17pt）。
    /// システムのインラインのタイトルと同じく、文字の大きさの設定では大きくしない（44pt のバーからはみ出さないため。大きな文字は Large Content Viewer が補う）
    static var b2InlineNavigationTitle: UIFont {
        UIFont(name: B2Font.Name.gothicBold, size: 17) ?? .systemFont(ofSize: 17, weight: .semibold)
    }

    /// ナビゲーションバーの大きなタイトルの書体（BIZ UDPゴシック Bold 34pt を、文字の大きさの設定に合わせた大きさにする）
    static var b2LargeNavigationTitle: UIFont {
        let base = UIFont(name: B2Font.Name.gothicBold, size: 34) ?? .systemFont(ofSize: 34, weight: .bold)
        return UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: base)
    }
}

enum B2NavigationBarAppearance {
    /// ナビゲーションバーのタイトル（通常と大きなタイトル）を BIZ UDPゴシック Bold にする。
    /// `.toolbarBackground` を付けた画面でも効くよう、titleTextAttributes ではなく UINavigationBarAppearance で当てる。
    /// 背景はシステムの既定のまま（スクロールの端では透明、それ以外は既定の背景）。
    /// UIFontMetrics の大きさは作ったときの設定で決まるので、アプリの起動時に 1 回呼ぶ
    static func apply() {
        let standard = UINavigationBarAppearance()
        standard.configureWithDefaultBackground()
        let scrollEdge = UINavigationBarAppearance()
        scrollEdge.configureWithTransparentBackground()
        for appearance in [standard, scrollEdge] {
            appearance.titleTextAttributes = [.font: UIFont.b2InlineNavigationTitle]
            appearance.largeTitleTextAttributes = [.font: UIFont.b2LargeNavigationTitle]
        }
        let proxy = UINavigationBar.appearance()
        proxy.standardAppearance = standard
        proxy.compactAppearance = standard
        proxy.scrollEdgeAppearance = scrollEdge
        proxy.compactScrollEdgeAppearance = scrollEdge
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
