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
        ("DottedLine", 0xB9AE92)
    ]

    /// すべての Color Set がアプリのバンドルから読める
    @Test(arguments: lightColors.map(\.name))
    func colorSetLoadsFromBundle(name: String) {
        #expect(UIColor(named: name, in: .main, compatibleWith: nil) != nil, "\(name) の Color Set が読めない")
    }

    /// ライトの値がモックの色と同じ（打ち間違いで別の色にならないように）
    @Test(arguments: lightColors)
    func lightValueMatchesMock(name: String, hex: UInt32) throws {
        let color = try #require(UIColor(named: name, in: .main, compatibleWith: UITraitCollection(userInterfaceStyle: .light)))
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
