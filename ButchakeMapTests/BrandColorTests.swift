//
//  BrandColorTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import Testing
import UIKit

/// B-2「駅のスタンプラリー」の色（Assets.xcassets の Color Set）
struct BrandColorTests {
    /// Color Set の名前と、ライトの値（docs/design/mocks/b2 の theme.css と README の配色の表）
    nonisolated static let lightColors: [(name: String, hex: UInt32)] = [
        ("AccentColor", 0x24387F),
        ("BrandPrimary", 0x24387F),
        ("BrandAccent", 0x2F7A45),
        ("Paper", 0xF7F3E8),
        ("Kraft", 0xE8DCC0),
        ("KraftBorder", 0xCDBF9C),
        ("Surface", 0xFFFFFF),
        ("TextPrimary", 0x1B1F2A),
        ("TextSecondary", 0x4F566A),
        ("CardBorder", 0xD9CFB6),
        ("SeparatorLine", 0xCFC4AA),
        ("TicketBorder", 0xC9C0A8),
        ("DottedLine", 0xB9AE92),
        ("TextOnColor", 0xFFFFFF)
    ]

    /// Color Set の名前と、ダークの値（docs/design/mocks/b2 の theme-dark.css と README の「ダークモードの配色（夜の駅）」の表）
    nonisolated static let darkColors: [(name: String, hex: UInt32)] = [
        ("AccentColor", 0xA3B6F5),
        ("BrandPrimary", 0xA3B6F5),
        ("BrandAccent", 0x6BC48A),
        ("Paper", 0x1E2230),
        ("Kraft", 0x4A3F2E),
        ("KraftBorder", 0x66573F),
        ("Surface", 0x2A2F40),
        ("TextPrimary", 0xECE7DA),
        ("TextSecondary", 0xBDB6A4),
        ("CardBorder", 0x474D60),
        ("SeparatorLine", 0x474D60),
        ("TicketBorder", 0x565D72),
        ("DottedLine", 0x9F987F),
        ("TextOnColor", 0x1E2230)
    ]

    /// すべての Color Set がアプリのバンドルから読める
    @Test(arguments: lightColors.map(\.name))
    func colorSetLoadsFromBundle(name: String) {
        #expect(UIColor(named: name, in: .main, compatibleWith: nil) != nil, "\(name) の Color Set が読めない")
    }

    /// ライトの値がモックの色と同じ（打ち間違いで別の色にならないように）
    @Test(arguments: lightColors)
    func lightValueMatchesMock(name: String, hex: UInt32) throws {
        try expectColor(name: name, style: .light, hex: hex)
    }

    /// ダークの値がモックの色と同じ
    @Test(arguments: darkColors)
    func darkValueMatchesMock(name: String, hex: UInt32) throws {
        try expectColor(name: name, style: .dark, hex: hex)
    }

    /// ライトとダークで同じ Color Set を確かめている（ダークの値の確かめ忘れが無いように）
    @Test
    func everyColorSetHasDarkValue() {
        #expect(Self.lightColors.map(\.name) == Self.darkColors.map(\.name))
    }

    private func expectColor(name: String, style: UIUserInterfaceStyle, hex: UInt32) throws {
        let traits = UITraitCollection(userInterfaceStyle: style)
        // UIColor(named:) は外観で変わる色を返すので、Simulator の外観によらずその外観の値に解決してから読む
        let color = try #require(UIColor(named: name, in: .main, compatibleWith: traits)).resolvedColor(with: traits)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        #expect(color.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        let actual = (UInt32((red * 255).rounded()) << 16) | (UInt32((green * 255).rounded()) << 8) | UInt32((blue * 255).rounded())
        #expect(actual == hex, "\(name) は #\(String(format: "%06X", hex)) のはずが #\(String(format: "%06X", actual))")
        #expect(alpha == 1)
    }
}
