//
//  DepartureBoardFlap.swift
//  ButchakeMap
//

import SwiftUI

/// 発車標の札の 1 桁分。回る前と後の数字を持つ（桁数が増減して、その桁が片方に無いときは nil）
nonisolated struct DepartureBoardFlapSlot: Equatable, Sendable {
    let from: String?
    let to: String?

    /// 前後で数字が違う桁だけを回す
    var turns: Bool {
        from != to
    }
}

/// 発車標の札がパタパタ回る動きの決まり（モックの motion.html の「いいね」。上半分がめくれて落ち、下半分が開く）
nonisolated enum DepartureBoardFlap {
    /// ハートを塗る時間（easeOut）。札はハートが塗られてから回り始める
    static let heartFillDuration: TimeInterval = 0.15
    /// 札の 1 段（上半分が落ちる・下半分が開く）の時間（easeIn）
    static let stageDuration: TimeInterval = 0.12
    /// 札が回る時間（2 段）
    static let turnDuration: TimeInterval = stageDuration * 2
    /// 押してから札が止まるまで（約 0.4 秒）
    static let totalDuration: TimeInterval = heartFillDuration + turnDuration
    /// 視差効果を減らすときの、ハートの塗りと件数のクロスフェードの時間
    static let crossfadeDuration: TimeInterval = 0.15

    /// 前後の数字を桁ごとに対応させる。1 の位どうしをそろえ（右寄せ）、桁の少ない方の上の桁は nil にする
    static func slots(from oldValue: Int, to newValue: Int) -> [DepartureBoardFlapSlot] {
        let oldDigits = DepartureBoardNumber.digits(of: oldValue)
        let newDigits = DepartureBoardNumber.digits(of: newValue)
        let count = max(oldDigits.count, newDigits.count)
        let paddedOld = padded(oldDigits, to: count)
        let paddedNew = padded(newDigits, to: count)
        return zip(paddedOld, paddedNew).map { DepartureBoardFlapSlot(from: $0, to: $1) }
    }

    /// 進み具合（0〜1）のときに並べる桁。回る前は前の数字の桁だけ、止まったら新しい数字の桁だけにし、
    /// 回っている間だけ両方の桁の札を並べる（無い側は数字の無い札にする）
    static func visibleSlots(_ slots: [DepartureBoardFlapSlot], progress: Double) -> [DepartureBoardFlapSlot] {
        if progress <= 0 {
            return slots.filter { $0.from != nil }
        }
        if progress >= 1 {
            return slots.filter { $0.to != nil }
        }
        return slots
    }

    /// 進み具合（0〜1。2 段の通しの時間に対して等速）を、上半分が落ちる段・下半分が開く段のそれぞれの進み具合（easeIn）に分ける
    static func stageProgress(_ progress: Double) -> (top: Double, bottom: Double) {
        let clamped = progress.isFinite ? min(max(progress, 0), 1) : 1
        let top = min(clamped * 2, 1)
        let bottom = max(clamped * 2 - 1, 0)
        return (eased(top, curve: .easeIn), eased(bottom, curve: .easeIn))
    }

    /// 押してからの時間を、札が回る進み具合（0〜1。等速）にする（ハートを塗る間は 0）
    static func turnProgress(at elapsed: TimeInterval) -> Double {
        guard elapsed.isFinite else {
            return 1
        }
        return min(max((elapsed - heartFillDuration) / turnDuration, 0), 1)
    }

    /// 押してからの時間を、ハートの塗りの進み具合（0〜1。easeOut）にする
    static func heartFill(at elapsed: TimeInterval) -> Double {
        guard elapsed.isFinite else {
            return 1
        }
        return eased(elapsed / heartFillDuration, curve: .easeOut)
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

    private static func padded(_ digits: [String], to count: Int) -> [String?] {
        Array(repeating: nil, count: count - digits.count) + digits.map { Optional($0) }
    }
}

/// いいねの件数を発車標の札で出す（モックの motion.html の .flap。文字色の地に白の BIZ UDPゴシック）。
/// 変わる桁だけ、上半分がめくれて落ち、下半分が開く。進み具合は外から渡す（いいねのボタンが KeyframeAnimator で進める）
struct DepartureBoardFlapCount: View {
    let slots: [DepartureBoardFlapSlot]
    /// 札が回る進み具合（0〜1。等速。段ごとの easeIn はこの中で掛ける）
    let progress: Double

    @ScaledMetric(relativeTo: Self.textStyle) private var scale: CGFloat = 1

    /// 札の大きさ（モックの 26x38px・角丸 4px・24px の文字・札の間 3px を、いいねの文字の 15pt に合わせて縮めた）
    private static let cardSize = CGSize(width: 16, height: 24)
    private static let cornerRadius: CGFloat = 3
    private static let spacing: CGFloat = 2
    private static let fontSize: CGFloat = 15
    private static let textStyle: Font.TextStyle = .subheadline
    /// 文字の大きさの設定で札を大きくするのは 2 倍まで（DepartureBoardNumber と同じ）
    private static let maxScale: CGFloat = 2
    /// 札の上半分・下半分を回すときの遠近の強さ
    private static let perspective: CGFloat = 0.35

    /// 回し終えた数字（止まっている札）
    init(value: Int) {
        self.init(slots: DepartureBoardFlap.slots(from: value, to: value), progress: 1)
    }

    /// 回っている途中の札（Preview・画像の書き出しでも進み具合を渡して使う）
    init(slots: [DepartureBoardFlapSlot], progress: Double) {
        self.slots = slots
        self.progress = progress
    }

    var body: some View {
        let factor = B2PartScale.clamped(scale, max: Self.maxScale)
        let metrics = CardMetrics(
            size: CGSize(width: Self.cardSize.width * factor, height: Self.cardSize.height * factor),
            cornerRadius: Self.cornerRadius * factor,
            font: .b2Heading(size: Self.fontSize * B2PartScale.fontAdjustment(scale, max: Self.maxScale), relativeTo: Self.textStyle)
        )
        let stages = DepartureBoardFlap.stageProgress(progress)
        let visible = DepartureBoardFlap.visibleSlots(slots, progress: progress)
        // 1 の位から数えた位置を id にする（桁数が変わっても同じ位の札を同じものとして扱う）
        let placed = visible.enumerated().map { (place: visible.count - $0.offset, slot: $0.element) }
        HStack(spacing: Self.spacing * factor) {
            ForEach(placed, id: \.place) { item in
                slotView(item.slot, stages: stages, metrics: metrics)
            }
        }
    }

    @ViewBuilder
    private func slotView(_ slot: DepartureBoardFlapSlot, stages: (top: Double, bottom: Double), metrics: CardMetrics) -> some View {
        if slot.turns {
            VStack(spacing: 0) {
                ZStack {
                    // 奥にある新しい数字の上半分。手前の前の数字の上半分が、下の辺を軸に手前へ落ちる
                    half(slot.to, edge: .top, metrics: metrics)
                    if stages.top < 1 {
                        half(slot.from, edge: .top, metrics: metrics)
                            .rotation3DEffect(
                                .degrees(-90 * stages.top),
                                axis: (x: 1, y: 0, z: 0),
                                anchor: .bottom,
                                perspective: Self.perspective
                            )
                    }
                }
                ZStack {
                    // 奥にある前の数字の下半分に、新しい数字の下半分が上の辺を軸に開いて重なる
                    half(slot.from, edge: .bottom, metrics: metrics)
                    if stages.bottom > 0 {
                        half(slot.to, edge: .bottom, metrics: metrics)
                            .rotation3DEffect(
                                .degrees(90 * (1 - stages.bottom)),
                                axis: (x: 1, y: 0, z: 0),
                                anchor: .top,
                                perspective: Self.perspective
                            )
                    }
                }
            }
            .overlay { seam }
        } else {
            card(slot.to, metrics: metrics)
                .overlay { seam }
        }
    }

    /// 札の上半分か下半分
    private func half(_ digit: String?, edge: VerticalEdge, metrics: CardMetrics) -> some View {
        card(digit, metrics: metrics)
            .frame(height: metrics.size.height / 2, alignment: edge == .top ? .top : .bottom)
            .clipped()
    }

    /// 1 桁の札（数字が無い桁は数字の無い札）
    private func card(_ digit: String?, metrics: CardMetrics) -> some View {
        Text(verbatim: digit ?? "")
            .font(metrics.font)
            .foregroundStyle(Color.surface)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(width: metrics.size.width, height: metrics.size.height)
            .background(Color.textPrimary, in: .rect(cornerRadius: metrics.cornerRadius))
    }

    /// 札の上下の境目（モックの 1px の線）
    private var seam: some View {
        Rectangle()
            .fill(Color.black.opacity(0.35))
            .frame(height: 1)
    }

    private struct CardMetrics {
        let size: CGSize
        let cornerRadius: CGFloat
        let font: Font
    }
}

private struct DepartureBoardFlapCountPreviewContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach([0, 0.25, 0.5, 0.75, 1], id: \.self) { progress in
                HStack(spacing: 16) {
                    DepartureBoardFlapCount(slots: DepartureBoardFlap.slots(from: 128, to: 129), progress: progress)
                    DepartureBoardFlapCount(slots: DepartureBoardFlap.slots(from: 129, to: 130), progress: progress)
                    DepartureBoardFlapCount(slots: DepartureBoardFlap.slots(from: 9, to: 10), progress: progress)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.paper)
    }
}

#Preview("発車標の札が回る") {
    DepartureBoardFlapCountPreviewContent()
}

#Preview("発車標の札が回る（大きな文字）") {
    DepartureBoardFlapCountPreviewContent()
        .environment(\.dynamicTypeSize, .accessibility5)
}
