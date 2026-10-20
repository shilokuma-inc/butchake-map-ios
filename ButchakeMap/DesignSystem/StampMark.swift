//
//  StampMark.swift
//  ButchakeMap
//

import SwiftUI

/// スタンプの大きな文字の書体
enum StampTypeface: Equatable {
    /// Kaisei Decol Bold（スタンプの書体。サブセットにある文字だけ）
    case stamp
    /// BIZ UDPゴシック Bold（サブセットに無い文字。市区町村の名前など）
    case heading

    /// 大きな文字の書体を選ぶ。スタンプの書体はサブセットなので、無い文字が 1 つでもあれば見出しの書体にする
    /// （無い文字をスタンプの書体に渡すと、代わりの書体で黙って出てしまうため）
    /// - Parameter covers: 文字がすべてスタンプの書体にあるか（既定は `B2Font.stampFontCovers(_:)`。テストで差し替える）
    static func forText(_ text: String, covers: @MainActor (String) -> Bool = B2Font.stampFontCovers) -> Self {
        covers(text) ? .stamp : .heading
    }

    func font(size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        switch self {
        case .stamp:
            .b2Stamp(size: size, relativeTo: textStyle)
        case .heading:
            .b2Heading(size: size, relativeTo: textStyle)
        }
    }
}

/// B-2 のスタンプ（紺一色のインクの二重丸。上の小さな文字・大きな文字・下の小さな文字）。
/// 飾りなので VoiceOver では読み上げない（Discussion #77 の Q2。同じ情報は呼び出し側の文言で読ませる）
struct StampMark: View {
    /// 上の小さな文字（日付など。DotGothic16）。空なら出さない
    var top = ""
    /// 大きな文字（「済」・日付など）。スタンプの書体に無い文字なら BIZ UDPゴシック Bold で出す
    let main: String
    /// 下の小さな文字（市区町村の名前など。DotGothic16）。空なら出さない
    var bottom = ""
    /// 丸の直径（標準の文字の大きさのとき。文字の大きさの設定に合わせて大きくなる）
    var size: CGFloat = StampMetrics.defaultSize

    @ScaledMetric(relativeTo: StampMetrics.textStyle) private var scale: CGFloat = 1

    private var diameter: CGFloat {
        size * B2PartScale.clamped(scale, max: StampMetrics.maxScale)
    }

    /// 文字の基の大きさ（丸の直径の比。モックの 64px の丸に 16px・9px・13px）。丸を大きくする上限を超えた分だけ下げる
    private func fontSize(_ ratio: CGFloat) -> CGFloat {
        size * ratio * B2PartScale.fontAdjustment(scale, max: StampMetrics.maxScale)
    }

    var body: some View {
        ZStack {
            StampRings(lineScale: B2PartScale.clamped(scale, max: StampMetrics.maxScale))
            // 行の間を詰める（モックの line-height: 1.1 に近づけ、上下の小さな文字を内側の線から離す）
            VStack(spacing: -diameter * 0.03) {
                if !top.isEmpty {
                    smallText(top)
                }
                Text(verbatim: main)
                    .font(StampTypeface.forText(main).font(size: fontSize(16 / 64), relativeTo: StampMetrics.textStyle))
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .frame(maxWidth: diameter * 0.74)
                if !bottom.isEmpty {
                    smallText(bottom)
                }
            }
            .frame(maxHeight: diameter * 0.72)
        }
        .foregroundStyle(Color.brandPrimary)
        .frame(width: diameter, height: diameter)
        .mask {
            StampInkWear()
        }
        .opacity(0.92)
        .rotationEffect(.degrees(-8))
        .accessibilityHidden(true)
    }

    private func smallText(_ text: String) -> some View {
        Text(verbatim: text)
            .font(.b2Ticket(size: fontSize(9 / 64), relativeTo: StampMetrics.textStyle))
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .frame(maxWidth: diameter * 0.6)
    }
}

/// スタンプの空き欄（点線の丸に補足の文字。例「？」「未」）。飾りなので VoiceOver では読み上げない
struct StampSlot: View {
    /// 丸の中の補足の文字（DotGothic16）
    var label = ""
    /// 丸の直径（標準の文字の大きさのとき）
    var size: CGFloat = StampMetrics.defaultSize

    @ScaledMetric(relativeTo: StampMetrics.textStyle) private var scale: CGFloat = 1

    private var diameter: CGFloat {
        size * B2PartScale.clamped(scale, max: StampMetrics.maxScale)
    }

    /// 文字の基の大きさ（丸の直径の比。モックの 64px の丸に 16px・9px・13px）。丸を大きくする上限を超えた分だけ下げる
    private func fontSize(_ ratio: CGFloat) -> CGFloat {
        size * ratio * B2PartScale.fontAdjustment(scale, max: StampMetrics.maxScale)
    }

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.dottedLine, style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
            if !label.isEmpty {
                Text(verbatim: label)
                    .font(.b2Ticket(size: fontSize(13 / 64), relativeTo: StampMetrics.textStyle))
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .frame(maxWidth: diameter * 0.74)
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityHidden(true)
    }
}

/// スタンプの大きさの決まり
enum StampMetrics {
    /// モックの .stamp-mark の 64px
    static let defaultSize: CGFloat = 64
    /// 丸と中の文字を同じだけ大きくするための文字のスタイル
    static let textStyle: Font.TextStyle = .callout
    /// 文字の大きさの設定で大きくするのは 2 倍まで（飾りなので、カードの中で場所を取りすぎないように）
    static let maxScale: CGFloat = 2
}

/// スタンプの二重丸（外 3pt の線、3pt の白のすき間、内 1.5pt の線。モックの border と box-shadow: inset 0 0 0 3px #FFFFFF, inset 0 0 0 4.5px ink）。
/// 線の太さは丸の大きさ（`size`）によらず決まった値で、文字の大きさの設定で丸を大きくしたときだけ同じ倍率で太くする
private struct StampRings: View {
    let lineScale: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.brandPrimary, lineWidth: 3 * lineScale)
            Circle()
                .inset(by: 3 * lineScale)
                .strokeBorder(Color.surface, lineWidth: 3 * lineScale)
            Circle()
                .inset(by: 6 * lineScale)
                .strokeBorder(Color.brandPrimary, lineWidth: 1.5 * lineScale)
        }
    }
}

/// インクのかすれ。スタンプに重ねる mask で、短い線を少しだけ抜く（アプリアイコンの icon.svg のかすれと同じ位置と向き）
private struct StampInkWear: View {
    /// 抜く線（丸の幅と高さを 1 とした位置）
    private static let strokes: [(from: CGPoint, to: CGPoint)] = [
        (CGPoint(x: 0.19, y: 0.25), CGPoint(x: 0.25, y: 0.23)),
        (CGPoint(x: 0.69, y: 0.16), CGPoint(x: 0.73, y: 0.18)),
        (CGPoint(x: 0.81, y: 0.75), CGPoint(x: 0.77, y: 0.78)),
        (CGPoint(x: 0.28, y: 0.84), CGPoint(x: 0.31, y: 0.85))
    ]

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))
            context.blendMode = .destinationOut
            let style = StrokeStyle(lineWidth: max(1, size.width * 0.02), lineCap: .round)
            for stroke in Self.strokes {
                var path = Path()
                path.move(to: CGPoint(x: stroke.from.x * size.width, y: stroke.from.y * size.height))
                path.addLine(to: CGPoint(x: stroke.to.x * size.width, y: stroke.to.y * size.height))
                context.stroke(path, with: .color(.black.opacity(0.7)), style: style)
            }
        }
    }
}

private struct StampMarkPreviewContent: View {
    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 16) {
                StampMark(top: "10.18", main: "済", bottom: "金沢")
                StampMark(top: "2026", main: "10.18", bottom: "金沢市")
                StampMark(top: "10.18", main: "公開", bottom: "金沢")
                StampSlot(label: "？")
            }
            HStack(spacing: 16) {
                // スタンプの書体に無い文字は BIZ UDPゴシック Bold になる
                StampMark(top: "10.12", main: "横浜", size: 56)
                StampMark(top: "10.18", main: "済", bottom: "金沢", size: 56)
                StampSlot(label: "未", size: 56)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.kraft)
    }
}

#Preview("スタンプ") {
    StampMarkPreviewContent()
}

#Preview("スタンプ（大きな文字）") {
    StampMarkPreviewContent()
        .environment(\.dynamicTypeSize, .accessibility5)
}
