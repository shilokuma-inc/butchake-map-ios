//
//  PublishStampView.swift
//  ButchakeMap
//

import SwiftUI

/// 公開したときにフォームの上に重ね、スタンプ帳の台紙にスタンプを押す動き（motion.html の「投稿の公開」）。
/// 動きの時間割りは `PublishStampTimeline`。終わったら onFinished を呼ぶ（呼び出し側が結果のアラートを出す）。
/// 飾りなので VoiceOver では読まない（公開したことは結果のアラートの「公開しました」で伝わる）
struct PublishStampView: View {
    let stamp: PublishStamp
    /// 動きの進み具合（秒）を外から決める。nil なら公開した時刻から時計で進める
    var elapsed: TimeInterval?
    /// Reduce Motion のときの動きにするかを外から決める（プレビュー・画像の書き出し用）。nil なら端末の設定に従う
    var reducesMotion: Bool?
    var onFinished: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var systemReducesMotion
    @State private var startDate = Date()
    @State private var pressCount = 0
    @State private var completeCount = 0
    @State private var isFinished = false

    private var reduceMotion: Bool {
        reducesMotion ?? systemReducesMotion
    }

    var body: some View {
        Group {
            if let elapsed {
                album(PublishStampTimeline.frame(at: elapsed, reduceMotion: reduceMotion))
            } else {
                TimelineView(.animation(paused: isFinished)) { context in
                    let time = context.date.timeIntervalSince(startDate)
                    album(PublishStampTimeline.frame(at: time, reduceMotion: reduceMotion))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.paper.ignoresSafeArea())
        // 重ねた台紙は飾り（読み上げない。結果はアラートで伝える）。スタンプは文字の大きさで最大 2 倍になり、
        // 3 こ並べると幅の狭い iPhone からはみ出し、スタンプ台とも大きさが合わなくなるので、標準の大きさで止める
        .dynamicTypeSize(...DynamicTypeSize.large)
        // 押した瞬間に重く、3 こそろったら成功の通知のハプティクス
        .sensoryFeedback(.impact(weight: .heavy), trigger: pressCount)
        .sensoryFeedback(.success, trigger: completeCount)
        .task {
            guard elapsed == nil else {
                return
            }
            await run()
        }
        .accessibilityHidden(true)
    }

    /// 時間割りの順に、ハプティクスを鳴らして終わりを知らせる
    private func run() async {
        let clock = ContinuousClock()
        let start = clock.now
        startDate = Date()
        for (time, event) in PublishStampTimeline.events(reduceMotion: reduceMotion, isComplete: stamp.isComplete) {
            do {
                try await clock.sleep(until: start.advanced(by: .seconds(time)))
            } catch {
                return
            }
            switch event {
            case .press:
                pressCount += 1
            case .complete:
                completeCount += 1
            case .finish:
                isFinished = true
                onFinished()
            }
        }
    }

    private func album(_ frame: PublishStampTimeline.Frame) -> some View {
        PublishStampAlbum(stamp: stamp, frame: frame)
    }
}

/// スタンプ帳の台紙の 1 ページ（モックの .album。クラフト紙の地に見出しとスタンプ 3 こ分の欄）
private struct PublishStampAlbum: View {
    let stamp: PublishStamp
    let frame: PublishStampTimeline.Frame

    /// モックの px を画面の pt にする倍率（モックのコマの幅 230px ほどに対して、画面の幅に見合う大きさにする）
    private static let scale: CGFloat = 1.4
    /// スタンプと欄の直径（モックの 60px）
    private static let stampSize: CGFloat = 60 * scale
    /// スタンプ台が上がりきったときの高さ
    private static let stamperRise: CGFloat = 120 * scale
    private static let message = PostCreateViewModel.Outcome.published.title

    var body: some View {
        VStack(alignment: .leading, spacing: 8 * Self.scale) {
            caption
            HStack(spacing: 8 * Self.scale) {
                ForEach(stamp.earlier) { earlier in
                    StampMark(top: earlier.date, main: earlier.place, size: Self.stampSize)
                }
                newStamp
                ForEach(0..<stamp.emptySlotCount, id: \.self) { _ in
                    StampSlot(label: "？", size: Self.stampSize)
                }
            }
            // 「公開しました」（結果のアラートの見出しと同じ文言）
            Text(Self.message)
                .font(StampTypeface.forText(String(localized: Self.message)).font(size: 14 * Self.scale, relativeTo: .headline))
                .foregroundStyle(Color.brandPrimary)
                .opacity(frame.messageOpacity)
                .padding(.top, 2 * Self.scale)
        }
        .padding(12 * Self.scale)
        // 縁も地と一緒に下に敷き、台紙の上に下りてくるスタンプ台を縁の線より手前に出す
        .background {
            RoundedRectangle(cornerRadius: 8 * Self.scale)
                .fill(Color.kraft)
                .strokeBorder(Color.kraftBorder, lineWidth: 1)
        }
    }

    /// 見出し（ホームのスタンプ帳と同じ「スタンプ帳 今月 N こ」。押したら数が 1 つ増える。
    /// モックは「2 / 3」だが、Discussion #77 の Q1 で目標が無いので分母は出さないと決めた）
    private var caption: some View {
        let count = frame.isStamped ? stamp.monthCount : max(stamp.monthCount - 1, 0)
        return HStack(spacing: 4 * Self.scale) {
            Text("Stamp Book")
            Text("This month: \(count)")
        }
        .font(.b2Heading(size: 14 * Self.scale, relativeTo: .subheadline))
        .foregroundStyle(Color.textPrimary)
    }

    /// 今押す欄。押すまでは空き欄、押したらインクの丸がにじんで収まる。スタンプ台はその上に重ねる
    private var newStamp: some View {
        ZStack {
            StampSlot(label: "？", size: Self.stampSize)
                .opacity(1 - frame.inkOpacity)
            StampMark(
                top: stamp.date,
                main: String(localized: PublishStamp.mainText),
                bottom: stamp.place,
                size: Self.stampSize
            )
            .scaleEffect(frame.inkScale)
            .opacity(frame.inkOpacity)
        }
        .overlay(alignment: .bottom) {
            if frame.stamperOpacity > 0 {
                Stamper(scale: Self.scale)
                    .offset(y: -Self.stamperRise * frame.stamperLift)
                    .opacity(frame.stamperOpacity)
            }
        }
    }
}

/// スタンプ台（モックの .stamper。紺がかった灰色の持ち手に、下に紺のインクの面）
private struct Stamper: View {
    let scale: CGFloat

    var body: some View {
        VStack(spacing: -2 * scale) {
            UnevenRoundedRectangle(
                topLeadingRadius: 10 * scale,
                bottomLeadingRadius: 4 * scale,
                bottomTrailingRadius: 4 * scale,
                topTrailingRadius: 10 * scale
            )
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Self.handleEdge, location: 0),
                        .init(color: Self.handleCenter, location: 0.5),
                        .init(color: Self.handleEdge, location: 1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 56 * scale, height: 76 * scale)
            RoundedRectangle(cornerRadius: 2 * scale)
                .fill(Color.brandPrimary)
                .frame(width: 48 * scale, height: 10 * scale)
        }
    }

    /// 持ち手の両端と真ん中の色（モックの linear-gradient(90deg, #3A3F4F, #6A7186 50%, #3A3F4F)）
    private static let handleEdge = Color(red: 0x3A / 255, green: 0x3F / 255, blue: 0x4F / 255)
    private static let handleCenter = Color(red: 0x6A / 255, green: 0x71 / 255, blue: 0x86 / 255)
}

#Preview("押した直後") {
    PublishStampView(
        stamp: PublishStamp(
            earlier: [
                .init(id: UUID(), date: "10.12", place: "横浜市"),
                .init(id: UUID(), date: "10.16", place: "札幌市")
            ],
            date: "10.18",
            place: "金沢市",
            monthCount: 3
        ),
        elapsed: 0.2
    )
}

#Preview("Reduce Motion") {
    PublishStampView(
        stamp: PublishStamp(earlier: [.init(id: UUID(), date: "10.12", place: "横浜市")], date: "10.18", place: "金沢市", monthCount: 2),
        reducesMotion: true
    )
}

#Preview("動き") {
    PublishStampView(
        stamp: PublishStamp(earlier: [.init(id: UUID(), date: "10.12", place: "横浜市")], date: "10.18", place: "金沢市", monthCount: 2)
    )
}
