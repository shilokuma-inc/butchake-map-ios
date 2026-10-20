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

    /// ライセンス文を画面の幅で折り返せるよう、段落の中の改行を空白にした文（文言は変えない）。
    ///
    /// - 空行はそのまま残す（段落の区切り）
    /// - 区切り線（`---` 以上の `-` だけの行）は前後で改行する
    /// - 空行・区切り線の直後の、英大文字だけの行（`PREAMBLE`・`PERMISSION & CONDITIONS` などの見出し）は、後ろで改行する
    /// - 行末の空白は取る
    static func reflowed(_ text: String) -> String {
        var output: [String] = []
        var paragraph: String?
        var isParagraphStart = true

        func flush() {
            if let paragraph {
                output.append(paragraph)
            }
            paragraph = nil
        }

        let lines = text.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
        for rawLine in lines {
            let line = String(rawLine.reversed().drop(while: \.isWhitespace).reversed())
            if line.isEmpty {
                flush()
                output.append("")
                isParagraphStart = true
            } else if isSeparator(line) || (isParagraphStart && isHeading(line)) {
                flush()
                output.append(line)
                isParagraphStart = isSeparator(line)
            } else {
                paragraph = paragraph.map { "\($0) \(line)" } ?? line
                isParagraphStart = false
            }
        }
        flush()
        return output.joined(separator: "\n")
    }

    /// `-` だけが 3 つ以上並んだ行（区切り線）
    static func isSeparator(_ line: String) -> Bool {
        line.count >= 3 && line.allSatisfy { $0 == "-" }
    }

    /// 英字を含み、小文字の無い行（見出し）
    private static func isHeading(_ line: String) -> Bool {
        line.contains(where: \.isLetter) && !line.contains(where: \.isLowercase)
    }
}
