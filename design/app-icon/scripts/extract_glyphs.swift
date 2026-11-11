// 書体のファイルから文字のアウトラインを取り出し、SVG のパスにして JSON に書き出す。extract_glyphs.sh から呼ぶ。
//
//   xcrun swift extract_glyphs.swift <出力の JSON> <キー>=<書体のファイル>=<文字>…
//
// 出力は { "<キー>": { "unitsPerEm": …, "glyphs": { "<文字>": { "d": …, "advance": …, "bbox": [x0, y0, x1, y1] } } } }。
// 座標は書体の単位（unitsPerEm）で、SVG に合わせて y を下向きにしている（ベースラインが y = 0）。
// 候補の SVG に文字をパスで埋め込むと、端末やフォントの有無で見た目が変わらない。

import CoreGraphics
import CoreText
import Foundation

struct ExtractError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}

/// 1 つの書体から取り出す設定
struct FontSpec {
    let key: String
    let url: URL
    let characters: [Character]

    init(argument: String) throws {
        let parts = argument.split(separator: "=", maxSplits: 2).map(String.init)
        guard parts.count == 3, !parts[0].isEmpty, !parts[2].isEmpty else {
            throw ExtractError("引数「\(argument)」は <キー>=<書体のファイル>=<文字> の形で書いてください")
        }
        key = parts[0]
        url = URL(fileURLWithPath: parts[1])
        characters = Array(parts[2])
    }
}

/// CGPath を SVG の d 属性の文字列にする（y を反転し、小数 1 桁に丸める）
func svgPathData(of path: CGPath) -> String {
    var commands: [String] = []
    func point(_ value: CGPoint) -> String {
        "\(format(value.x)) \(format(-value.y))"
    }
    path.applyWithBlock { pointer in
        let element = pointer.pointee
        let points = element.points
        switch element.type {
        case .moveToPoint:
            commands.append("M\(point(points[0]))")
        case .addLineToPoint:
            commands.append("L\(point(points[0]))")
        case .addQuadCurveToPoint:
            commands.append("Q\(point(points[0])) \(point(points[1]))")
        case .addCurveToPoint:
            commands.append("C\(point(points[0])) \(point(points[1])) \(point(points[2]))")
        case .closeSubpath:
            commands.append("Z")
        @unknown default:
            break
        }
    }
    return commands.joined()
}

/// 小数 1 桁に丸める
func rounded(_ value: CGFloat) -> Double {
    (Double(value) * 10).rounded() / 10
}

func format(_ value: CGFloat) -> String {
    let value = rounded(value)
    if value == value.rounded() {
        return String(Int(value))
    }
    return String(format: "%.1f", value)
}

func extract(_ spec: FontSpec) throws -> [String: Any] {
    guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(spec.url as CFURL) as? [CTFontDescriptor],
          let descriptor = descriptors.first else {
        throw ExtractError("\(spec.url.path) を書体として読めません")
    }
    // 大きさを unitsPerEm にすると、パスの座標が書体の単位になる
    let probe = CTFontCreateWithFontDescriptor(descriptor, 1000, nil)
    let unitsPerEm = CGFloat(CTFontGetUnitsPerEm(probe))
    let font = CTFontCreateWithFontDescriptor(descriptor, unitsPerEm, nil)

    var glyphs: [String: Any] = [:]
    for character in spec.characters {
        let utf16 = Array(String(character).utf16)
        var glyphIDs = [CGGlyph](repeating: 0, count: utf16.count)
        guard CTFontGetGlyphsForCharacters(font, utf16, &glyphIDs, utf16.count), let glyph = glyphIDs.first, glyph != 0 else {
            throw ExtractError("\(spec.url.lastPathComponent) に「\(character)」の字形がありません")
        }
        var advance = CGSize.zero
        CTFontGetAdvancesForGlyphs(font, .horizontal, [glyph], &advance, 1)
        guard let path = CTFontCreatePathForGlyph(font, glyph, nil) else {
            throw ExtractError("\(spec.url.lastPathComponent) の「\(character)」のアウトラインを取り出せません")
        }
        let box = path.boundingBoxOfPath
        let bbox: [Double] = [box.minX, -box.maxY, box.maxX, -box.minY].map { rounded($0) }
        let entry: [String: Any] = [
            "d": svgPathData(of: path),
            "advance": rounded(advance.width),
            "bbox": bbox
        ]
        glyphs[String(character)] = entry
    }
    return [
        "font": CTFontCopyFullName(font) as String,
        "unitsPerEm": Int(unitsPerEm),
        "glyphs": glyphs
    ]
}

let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments.count >= 2 else {
    FileHandle.standardError.write(Data("使い方: xcrun swift extract_glyphs.swift <出力の JSON> <キー>=<書体のファイル>=<文字>…\n".utf8))
    exit(2)
}

do {
    let outputURL = URL(fileURLWithPath: arguments[0])
    var fonts: [String: Any] = [:]
    for argument in arguments.dropFirst() {
        let spec = try FontSpec(argument: argument)
        fonts[spec.key] = try extract(spec)
    }
    let data = try JSONSerialization.data(withJSONObject: fonts, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
    try data.write(to: outputURL)
    try FileHandle.standardOutput.write(contentsOf: Data("\(outputURL.path) に書き出しました\n".utf8))
} catch {
    FileHandle.standardError.write(Data("エラー: \(error)\n".utf8))
    exit(1)
}
