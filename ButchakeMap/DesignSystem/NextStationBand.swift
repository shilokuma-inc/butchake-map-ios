//
//  NextStationBand.swift
//  ButchakeMap
//

import SwiftUI

/// 「次の駅へ」の 1 コマ（紺の丸の進み具合と、中身の不透明度）
nonisolated struct NextStationFrame: Equatable, Sendable {
    /// 紺の丸の進み具合（0 で前の駅、1 で次の駅。easeInOut を掛けた後の値）
    let markerProgress: Double
    /// 帯と詳細の中身の不透明度（視差効果を減らすときのクロスフェード。ふだんは 1）
    let contentOpacity: Double

    /// 次の駅に着いて止まったコマ
    static let arrived = Self(markerProgress: 1, contentOpacity: 1)
}

/// 投稿詳細へ進むときの「次の駅へ」の動きの決まり（モックの motion.html と README の「動き」の表）。
/// 詳細が開いてから 0.1 秒待ち、上の路線の帯の紺の丸が easeInOut 0.35 秒で前の駅から次の駅へ進む（0.45 秒で着く）。
/// 視差効果を減らすときは丸を動かさず（最初から次の駅）、帯と中身を 0.2 秒でクロスフェードする
nonisolated enum NextStationMotion {
    /// 開いてから紺の丸が動き始めるまで
    static let delay: TimeInterval = 0.1
    /// 紺の丸が前の駅から次の駅へ進む時間（easeInOut）
    static let travelDuration: TimeInterval = 0.35
    /// 開いてから次の駅に着くまで（0.45 秒。着いたときに selection を鳴らす）
    static let totalDuration: TimeInterval = delay + travelDuration
    /// 視差効果を減らすときの、帯と中身のクロスフェードの時間
    static let crossfadeDuration: TimeInterval = 0.2

    /// 帯の駅の位置（帯の幅に対する割合。前の駅・次の駅・その先の駅。モックの .bar の i）
    static let stationFractions: [Double] = [0, 0.5, 1]
    /// 紺の丸が出る駅（前の駅＝一覧）と着く駅（次の駅＝この投稿）の位置
    static let departureFraction: Double = 0
    static let arrivalFraction: Double = 0.5

    /// 開いてからの時間を、紺の丸の進み具合（0〜1。easeInOut）にする。動き始める前は 0、着いたら 1
    static func markerProgress(at elapsed: TimeInterval) -> Double {
        guard elapsed.isFinite else {
            return 1
        }
        return eased((elapsed - delay) / travelDuration, curve: .easeInOut)
    }

    /// 紺の丸の進み具合（0〜1）を、帯の幅に対する丸の中心の位置（前の駅から次の駅まで）にする
    static func markerFraction(progress: Double) -> Double {
        let clamped = progress.isFinite ? min(max(progress, 0), 1) : 1
        return departureFraction + (arrivalFraction - departureFraction) * clamped
    }

    /// 視差効果を減らすときの、開いてからの時間に対する帯と中身の不透明度（0〜1。easeInOut）
    static func crossfadeOpacity(at elapsed: TimeInterval) -> Double {
        guard elapsed.isFinite else {
            return 1
        }
        return eased(elapsed / crossfadeDuration, curve: .easeInOut)
    }

    /// 開いてからの時間のコマ（画像の書き出しと、アニメーションの値の確かめに使う）
    static func frame(at elapsed: TimeInterval, reduceMotion: Bool) -> NextStationFrame {
        if reduceMotion {
            NextStationFrame(markerProgress: 1, contentOpacity: crossfadeOpacity(at: elapsed))
        } else {
            NextStationFrame(markerProgress: markerProgress(at: elapsed), contentOpacity: 1)
        }
    }

    /// アニメーションの始まり（着いたか）と終わりのコマ。アニメーションはこの 2 つの間を `animation(reduceMotion:)` で補う。
    /// 視差効果を減らすときは丸を最初から次の駅に置き、不透明度だけを 0 から 1 にする
    static func frame(hasArrived: Bool, reduceMotion: Bool) -> NextStationFrame {
        if hasArrived {
            .arrived
        } else if reduceMotion {
            NextStationFrame(markerProgress: 1, contentOpacity: 0)
        } else {
            NextStationFrame(markerProgress: 0, contentOpacity: 1)
        }
    }

    /// 開いてから着いたとき（ハプティクスを鳴らすまで）の時間
    static func arrivalDelay(reduceMotion: Bool) -> TimeInterval {
        reduceMotion ? crossfadeDuration : totalDuration
    }

    /// 始まりのコマから着いたコマへの動き（`markerProgress(at:)`・`crossfadeOpacity(at:)` と同じ時間とイージング）
    static func animation(reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .easeInOut(duration: crossfadeDuration)
            : .easeInOut(duration: travelDuration).delay(delay)
    }

    /// 0〜1 にそろえてイージングを掛ける（両端はちょうど 0 と 1）
    private static func eased(_ value: Double, curve: UnitCurve) -> Double {
        if value <= 0 {
            return 0
        }
        if value >= 1 {
            return 1
        }
        return curve.value(at: value)
    }
}

/// 投稿詳細の上に出す路線の帯（モックの motion.html の .bar。路線の緑の線・白地に緑の枠の駅の丸・紺の丸）。
/// 紺の丸は前の駅（一覧）から次の駅（この投稿）へ進む。飾りなので VoiceOver では読まない
struct NextStationBand: View {
    /// 紺の丸の進み具合（0 で前の駅、1 で次の駅。easeInOut を掛けた後の値）
    let progress: Double

    @ScaledMetric(relativeTo: RouteMetrics.textStyle) private var scale: CGFloat = 1

    /// モックの .bar の大きさ（線の太さ 6px・駅の丸 18px と枠 4px・紺の丸 24px）
    private static let lineHeight: CGFloat = 6
    private static let stationDiameter: CGFloat = 18
    private static let stationBorder: CGFloat = 4
    private static let markerDiameter: CGFloat = 24

    var body: some View {
        // 文字の大きさの設定で帯を大きくするのは、路線図の駅と同じく 2 倍まで
        let factor = B2PartScale.clamped(scale, max: RouteMetrics.maxScale)
        let markerDiameter = Self.markerDiameter * factor
        let stationDiameter = Self.stationDiameter * factor
        GeometryReader { proxy in
            // 両端の駅の丸が切れないよう、紺の丸の半径の分だけ内側に線を引く
            let inset = markerDiameter / 2
            let track = max(proxy.size.width - inset * 2, 0)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.brandAccent)
                    .frame(width: track, height: Self.lineHeight * factor)
                    .offset(x: inset)
                ForEach(NextStationMotion.stationFractions, id: \.self) { fraction in
                    Circle()
                        .fill(Color.surface)
                        .overlay {
                            Circle()
                                .strokeBorder(Color.brandAccent, lineWidth: Self.stationBorder * factor)
                        }
                        .frame(width: stationDiameter, height: stationDiameter)
                        .offset(x: inset + track * fraction - stationDiameter / 2)
                }
                Circle()
                    .fill(Color.brandPrimary)
                    .frame(width: markerDiameter, height: markerDiameter)
                    .offset(x: track * NextStationMotion.markerFraction(progress: progress))
            }
            .frame(width: proxy.size.width, height: markerDiameter, alignment: .leading)
        }
        .frame(height: markerDiameter)
        .accessibilityHidden(true)
    }
}

/// 路線の帯と、その下の中身（投稿詳細）。初めて表示されたときだけ、紺の丸を次の駅へ進め、着いたら selection を鳴らす。
/// 戻って再び表示されたときや、中身が変わったとき（いいね・編集）は動かさない
struct NextStationArrival<Content: View>: View {
    /// 外から渡したコマ（Preview・画像の書き出し用）。nil なら初めて表示されたときに動かす
    private let fixedFrame: NextStationFrame?
    private let spacing: CGFloat
    private let content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 紺の丸が次の駅に着いたか（一度着いたら、この画面の間は着いたまま）
    @State private var hasArrived = false
    /// 着くたびに増やす（selection のハプティクスのきっかけ）
    @State private var arrivalCount = 0

    init(spacing: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.init(frame: nil, spacing: spacing, content: content)
    }

    /// 決まったコマで止めて出す（Preview・画像の書き出しで進み具合を渡して使う）
    init(frame: NextStationFrame?, spacing: CGFloat = 16, @ViewBuilder content: () -> Content) {
        fixedFrame = frame
        self.spacing = spacing
        self.content = content()
    }

    private var currentFrame: NextStationFrame {
        fixedFrame ?? NextStationMotion.frame(hasArrived: hasArrived, reduceMotion: reduceMotion)
    }

    var body: some View {
        let frame = currentFrame
        VStack(alignment: .leading, spacing: spacing) {
            NextStationBand(progress: frame.markerProgress)
            content
        }
        .opacity(frame.contentOpacity)
        .task {
            guard fixedFrame == nil, !hasArrived else {
                return
            }
            let reduceMotion = reduceMotion
            withAnimation(NextStationMotion.animation(reduceMotion: reduceMotion)) {
                hasArrived = true
            }
            // 着く前に戻ったら（task が取り消されたら）鳴らさない
            try? await Task.sleep(for: .seconds(NextStationMotion.arrivalDelay(reduceMotion: reduceMotion)))
            guard !Task.isCancelled else {
                return
            }
            arrivalCount &+= 1
        }
        .sensoryFeedback(.selection, trigger: arrivalCount)
    }
}

private struct NextStationBandPreviewContent: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach([0, 0.1, 0.2, 0.3, 0.4, 0.45], id: \.self) { elapsed in
                NextStationBand(progress: NextStationMotion.markerProgress(at: elapsed))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.paper)
    }
}

#Preview("次の駅へ（帯のコマ）") {
    NextStationBandPreviewContent()
}

#Preview("次の駅へ（帯のコマ・大きな文字）") {
    NextStationBandPreviewContent()
        .environment(\.dynamicTypeSize, .accessibility5)
}
