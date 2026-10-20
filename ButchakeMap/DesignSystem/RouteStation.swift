//
//  RouteStation.swift
//  ButchakeMap
//

import SwiftUI

/// 路線図の駅の丸（白の地に路線の緑の枠、DotGothic16 の順位の番号）。
/// 番号は読み上げない（読み上げは呼び出し側の文言に任せ、今の画面の読み上げを変えない）
struct RouteRankBadge: View {
    enum Style {
        /// 一覧の行の番号（モックの .rank。26pt・枠 2.5pt・15pt の番号）。今の SpotNameRow の番号の丸の代わり
        case compact
        /// 路線図の駅（モックの .stop > .rank。34pt・枠 4pt・18pt の番号）
        case station

        var diameter: CGFloat {
            switch self {
            case .compact:
                26
            case .station:
                RouteMetrics.stationDiameter
            }
        }

        var borderWidth: CGFloat {
            switch self {
            case .compact:
                2.5
            case .station:
                4
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .compact:
                15
            case .station:
                18
            }
        }
    }

    let number: Int
    var style = Style.compact

    @ScaledMetric(relativeTo: RouteMetrics.textStyle) private var scale: CGFloat = 1

    private var diameter: CGFloat {
        style.diameter * B2PartScale.clamped(scale, max: RouteMetrics.maxScale)
    }

    /// 番号の基の大きさ（丸を大きくする上限を超えた分だけ下げる）
    private var fontSize: CGFloat {
        style.fontSize * B2PartScale.fontAdjustment(scale, max: RouteMetrics.maxScale)
    }

    var body: some View {
        Text(verbatim: String(number))
            .font(.b2Ticket(size: fontSize, relativeTo: RouteMetrics.textStyle))
            .foregroundStyle(Color.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(style.borderWidth + 1)
            .frame(width: diameter, height: diameter)
            .background(Color.surface, in: .circle)
            .overlay {
                Circle()
                    .strokeBorder(Color.brandAccent, lineWidth: style.borderWidth)
            }
            .accessibilityHidden(true)
    }
}

/// 路線図。駅（`RouteStationRow`）を縦に並べ、左に路線の緑の線（太さ 8pt・角丸）を引く
struct RouteLine<Content: View>: View {
    /// 駅と駅の間（モックの .route の gap）
    var spacing: CGFloat = 18
    @ViewBuilder let content: Content

    @ScaledMetric(relativeTo: RouteMetrics.textStyle) private var scale: CGFloat = 1

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
        .background(alignment: .topLeading) {
            let center = RouteMetrics.stationDiameter * B2PartScale.clamped(scale, max: RouteMetrics.maxScale) / 2
            RoundedRectangle(cornerRadius: RouteMetrics.lineWidth / 2)
                .fill(Color.brandAccent)
                .frame(width: RouteMetrics.lineWidth)
                .padding(.top, RouteMetrics.lineTop)
                .offset(x: center - RouteMetrics.lineWidth / 2)
                .accessibilityHidden(true)
        }
    }
}

/// 路線図の 1 つの駅。左に駅の丸、右に中身（駅のカードなど）を置く。`RouteLine` の中に並べる
struct RouteStationRow<Content: View>: View {
    let number: Int
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: RouteMetrics.stationSpacing) {
            RouteRankBadge(number: number, style: .station)
                .padding(.top, RouteMetrics.stationTop)
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// 路線図の大きさの決まり（モックの detail.css の .route と .stop）
enum RouteMetrics {
    /// 駅の丸の直径（線はこの丸の中心を通る）
    static let stationDiameter: CGFloat = 34
    /// 駅の丸と中身の間（.route の padding-left 40px − 丸の 34px）
    static let stationSpacing: CGFloat = 6
    /// 中身の上端から駅の丸までの間（.stop > .rank の top）
    static let stationTop: CGFloat = 8
    /// 線の太さ
    static let lineWidth: CGFloat = 8
    /// 線の上端（.route::before の top）
    static let lineTop: CGFloat = 6
    /// 丸と番号を同じだけ大きくするための文字のスタイル
    static let textStyle: Font.TextStyle = .body
    /// 文字の大きさの設定で丸を大きくするのは 2 倍まで（番号は丸に収まるよう縮む）
    static let maxScale: CGFloat = 2
}

private struct RouteStationPreviewContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(1...3, id: \.self) { number in
                    HStack(spacing: 8) {
                        RouteRankBadge(number: number)
                        Text(verbatim: "すし食いねぇ！ 県庁前店")
                            .font(.b2Body)
                    }
                }
            }
            RouteLine {
                ForEach(1...3, id: \.self) { number in
                    RouteStationRow(number: number) {
                        Text(verbatim: "もりもり寿し 近江町店")
                            .font(.b2Heading(size: 18))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.surface, in: .rect(cornerRadius: 8))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.cardBorder, lineWidth: 1)
                            }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.paper)
    }
}

#Preview("路線図の駅") {
    RouteStationPreviewContent()
}

#Preview("路線図の駅（大きな文字）") {
    RouteStationPreviewContent()
        .environment(\.dynamicTypeSize, .accessibility5)
}
