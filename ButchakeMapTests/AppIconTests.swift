//
//  AppIconTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import Testing
import UIKit

/// アプリアイコン（ButchakeMap/AppIcon.icon と Assets.xcassets/AppIcon.appiconset。どちらも名前は AppIcon）
struct AppIconTests {
    /// actool が Info.plist に AppIcon を書き込み、iOS 17〜25 のホーム画面用の PNG（60pt の @2x）をバンドルに置いている
    ///
    /// `UIImage(named: "AppIcon")` は使わない。.icon から作られたアセットカタログでは
    /// 'Need an imageRef' の例外でテストのプロセスごと落ちるため（Xcode 26.6・iOS 26.5 の Simulator で確認）。
    @Test
    func appIconIsRegisteredInBundle() throws {
        let icons = try #require(
            Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
            "Info.plist に CFBundleIcons が無い"
        )
        let primary = try #require(icons["CFBundlePrimaryIcon"] as? [String: Any])
        #expect(primary["CFBundleIconName"] as? String == "AppIcon")
        let files = try #require(primary["CFBundleIconFiles"] as? [String])
        #expect(files.contains("AppIcon60x60"))

        let path = try #require(Bundle.main.path(forResource: "AppIcon60x60@2x", ofType: "png"), "AppIcon60x60@2x.png が無い")
        let image = try #require(UIImage(contentsOfFile: path), "AppIcon60x60@2x.png が読めない")
        #expect(image.size.width * image.scale == 120)
        #expect(image.size.height * image.scale == 120)
    }
}
