//
//  FontLicense.swift
//  ButchakeMap
//

import Foundation

/// アプリに同梱している書体と、そのライセンス文（ButchakeMap/Resources/Fonts の <書体>-OFL.txt）
nonisolated enum FontLicense: CaseIterable, Identifiable, Sendable {
    case bizUDPGothic
    case dotGothic16
    case kaiseiDecol

    var id: Self { self }

    /// 書体の名前（固有名詞なので翻訳しない）
    var familyName: String {
        switch self {
        case .bizUDPGothic:
            "BIZ UDPGothic"
        case .dotGothic16:
            "DotGothic16"
        case .kaiseiDecol:
            "Kaisei Decol"
        }
    }

    /// ライセンスの名前（固有名詞なので翻訳しない）
    var licenseName: String { "SIL Open Font License 1.1" }

    /// ライセンス文のファイル名（拡張子なし）。フォルダ同期で .app の直下に入る
    var licenseFileName: String {
        switch self {
        case .bizUDPGothic:
            "BIZUDPGothic-OFL"
        case .dotGothic16:
            "DotGothic16-OFL"
        case .kaiseiDecol:
            "KaiseiDecol-OFL"
        }
    }

    /// ライセンス文の全文。読めなければ nil
    func licenseText(in bundle: Bundle = .main) -> String? {
        guard let url = bundle.url(forResource: licenseFileName, withExtension: "txt") else {
            return nil
        }
        return try? String(contentsOf: url, encoding: .utf8)
    }
}
