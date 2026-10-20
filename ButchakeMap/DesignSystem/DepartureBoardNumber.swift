//
//  DepartureBoardNumber.swift
//  ButchakeMap
//

import SwiftUI

/// 発車標の数字（いいねの件数など）。桁ごとの札（文字色の地に白の DotGothic16）を並べる。
/// いいねの札を回す動きは DepartureBoardFlapCount（DepartureBoardFlap.swift）。VoiceOver では数字として読む
struct DepartureBoardNumber: View {
    let value: Int

    @ScaledMetric(relativeTo: Self.textStyle) private var scale: CGFloat = 1

    /// 札の大きさ・文字の大きさ（モックの motion.html の .flap span。26x38px・角丸 4px・24px の文字・札の間 3px）
    private static let cardSize = CGSize(width: 26, height: 38)
    private static let cornerRadius: CGFloat = 4
    private static let spacing: CGFloat = 3
    private static let fontSize: CGFloat = 24
    private static let textStyle: Font.TextStyle = .title2
    /// 文字の大きさの設定で札を大きくするのは 2 倍まで（桁が多くても横にあふれにくくする。数字は札に収まるよう縮む）
    private static let maxScale: CGFloat = 2

    /// 数字を桁に分ける（桁区切りは付けない。負の数は先頭に「-」の札）
    nonisolated static func digits(of value: Int) -> [String] {
        String(value).map(String.init)
    }

    var body: some View {
        let factor = B2PartScale.clamped(scale, max: Self.maxScale)
        let fontSize = Self.fontSize * B2PartScale.fontAdjustment(scale, max: Self.maxScale)
        HStack(spacing: Self.spacing * factor) {
            ForEach(Array(Self.digits(of: value).enumerated()), id: \.offset) { _, digit in
                Text(verbatim: digit)
                    .font(.b2Ticket(size: fontSize, relativeTo: Self.textStyle))
                    .foregroundStyle(Color.surface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(width: Self.cardSize.width * factor, height: Self.cardSize.height * factor)
                    .background(Color.textPrimary, in: .rect(cornerRadius: Self.cornerRadius))
                    .overlay {
                        // 札の上下の境目（モックの 1px の線）
                        Rectangle()
                            .fill(Color.black.opacity(0.35))
                            .frame(height: 1)
                    }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(value, format: .number.grouping(.never)))
    }
}

private struct DepartureBoardNumberPreviewContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DepartureBoardNumber(value: 128)
            DepartureBoardNumber(value: 0)
            DepartureBoardNumber(value: 12_345)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.paper)
    }
}

#Preview("発車標の数字") {
    DepartureBoardNumberPreviewContent()
}

#Preview("発車標の数字（大きな文字）") {
    DepartureBoardNumberPreviewContent()
        .environment(\.dynamicTypeSize, .accessibility5)
}
