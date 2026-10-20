//
//  PublishStamp.swift
//  ButchakeMap
//
//  投稿を公開したときにスタンプ帳の台紙へスタンプを押す動き（B-2「駅のスタンプラリー」の motion.html）の中身と時間割り。
//  画面に依らない値の計算だけを置き、描くのは PublishStampView
//

import Foundation
import SwiftUI

/// 公開したときに押すスタンプと、それを押す台紙の 1 ページ。
/// 台紙は 3 こで 1 ページ（ホームのスタンプ帳と同じ、今月の自分の公開済みの投稿 1 つ = スタンプ 1 こ）。
/// 今月の 1・4・7… こ目は新しいページの 1 こ目になり、3・6・9… こ目でページの 3 こがそろう
struct PublishStamp: Equatable {
    /// 台紙の 1 ページの欄の数（ホームのスタンプ帳に並べる数と同じ）
    static let slotCount = StampBook.visibleStampLimit
    /// スタンプの真ん中の文字（日本語は「公開」。スタンプの書体のサブセットにある）
    static let mainText: LocalizedStringResource = "Published"

    /// 同じページに先に押してあるスタンプ（古い順）
    let earlier: [StampBook.Stamp]
    /// 今押すスタンプの上の文字（公開日の「M.d」）
    let date: String
    /// 今押すスタンプの下の文字（市区町村、空なら都道府県）
    let place: String
    /// 押したあとの今月のスタンプの数（見出しの「今月 N こ」。Discussion #77 の Q1 のとおり分母は出さない）
    var monthCount = 1

    /// 押したあとにページで埋まっている欄の数
    var filledCount: Int {
        earlier.count + 1
    }

    /// 押したあとの空き欄の数
    var emptySlotCount: Int {
        max(0, Self.slotCount - filledCount)
    }

    /// 押してページの 3 こがそろったか（そろったときだけ success のハプティクスを鳴らす）
    var isComplete: Bool {
        filledCount == Self.slotCount
    }

    /// 公開したあとのスタンプ帳から、押すスタンプと同じページの先のスタンプを決める。
    /// 公開した投稿が今月のスタンプに入っていなければ（今月に公開した投稿でなければ）nil
    /// - Parameters:
    ///   - book: 公開したあとのホームのスタンプ帳（`HomeViewModel.stampBook`。今月の新しい 3 こを古い順に）
    ///   - published: 公開した投稿
    static func make(book: StampBook, published: Post, calendar: Calendar = .current) -> Self? {
        guard book.stamps.contains(where: { $0.id == published.id }) else {
            return nil
        }
        // 今月の何こ目がページのどこに入るか（1 こ目 = 0）。先に押してあるのはページのその前まで
        let indexOnPage = max(book.count - 1, 0) % slotCount
        let earlier = book.stamps.filter { $0.id != published.id }.suffix(indexOnPage)
        return Self(
            earlier: Array(earlier),
            date: PostDetailViewModel.stampDate(of: published, calendar: calendar),
            place: PostDetailViewModel.stampPlace(of: published),
            monthCount: book.count
        )
    }
}

/// スタンプを押す動きの時間割り（motion.html の「投稿の公開（スタンプを押す）」。全体 1.0 秒）。
/// スタンプ台が easeIn 0.2 秒で下りて押し、0.08 秒止まって easeOut で上がる。インクの丸は 1.1 倍からにじんで 1.0 倍になる。
/// Reduce Motion のときはスタンプ台を出さず、インクの丸と「公開しました」を 0.2 秒でフェードインする
enum PublishStampTimeline {
    /// 動き全体の長さ。終わったら結果のアラートを出す（Reduce Motion のときも同じだけ見せる）
    static let duration: TimeInterval = 1.0
    /// スタンプ台が下りきって押す時刻
    static let pressTime: TimeInterval = 0.2
    /// 押したまま止まり終える時刻（0.08 秒止まる）
    static let holdEndTime: TimeInterval = 0.28
    /// スタンプ台が上がりきって消える時刻。インクのにじみもここで 1.0 倍に収まる
    static let liftEndTime: TimeInterval = 0.6
    /// 「公開しました」を出し始める時刻と、出しきる時刻
    static let messageStartTime: TimeInterval = 0.6
    static let messageEndTime: TimeInterval = 0.8
    /// Reduce Motion のときのフェードインの長さ
    static let reduceMotionFadeDuration: TimeInterval = 0.2
    /// 押した瞬間のインクの丸の大きさ（倍）
    static let inkStartScale: Double = 1.1

    /// ある時刻の見た目
    struct Frame: Equatable {
        /// スタンプ台の高さ（0 = 台紙に押している位置、1 = 上がりきった位置）
        var stamperLift: Double
        /// スタンプ台の不透明度（0 なら出さない）
        var stamperOpacity: Double
        /// インクの丸（押したスタンプ）の不透明度
        var inkOpacity: Double
        /// インクの丸の大きさ（倍）
        var inkScale: Double
        /// 「公開しました」の不透明度
        var messageOpacity: Double
        /// 台紙の数に今押すスタンプを入れたか（見出しの「N / 3」）
        var isStamped: Bool
    }

    /// 動きの途中で起きること（ハプティクスと、終わり）
    enum Event: Equatable {
        /// スタンプを押した（impact・heavy）
        case press
        /// ページの 3 こがそろった（notification・success）
        case complete
        /// 動きが終わった（結果のアラートを出す）
        case finish
    }

    /// elapsed 秒の見た目
    static func frame(at elapsed: TimeInterval, reduceMotion: Bool) -> Frame {
        let time = min(max(elapsed, 0), duration)
        if reduceMotion {
            let fade = UnitCurve.easeInOut.value(at: progress(time, from: 0, to: reduceMotionFadeDuration))
            return Frame(stamperLift: 1, stamperOpacity: 0, inkOpacity: fade, inkScale: 1, messageOpacity: fade, isStamped: true)
        }
        let isStamped = time >= pressTime
        let lift: Double
        let stamperOpacity: Double
        if time < pressTime {
            // 上から下りてくる（easeIn）
            lift = 1 - UnitCurve.easeIn.value(at: progress(time, from: 0, to: pressTime))
            stamperOpacity = 1
        } else if time < holdEndTime {
            // 押したまま止まる
            lift = 0
            stamperOpacity = 1
        } else {
            // 上がりながら消える（easeOut）
            let rise = progress(time, from: holdEndTime, to: liftEndTime)
            lift = UnitCurve.easeOut.value(at: rise)
            stamperOpacity = 1 - rise
        }
        let settle = UnitCurve.easeOut.value(at: progress(time, from: pressTime, to: liftEndTime))
        return Frame(
            stamperLift: lift,
            stamperOpacity: stamperOpacity,
            inkOpacity: isStamped ? 1 : 0,
            inkScale: isStamped ? inkStartScale - (inkStartScale - 1) * settle : inkStartScale,
            messageOpacity: UnitCurve.easeOut.value(at: progress(time, from: messageStartTime, to: messageEndTime)),
            isStamped: isStamped
        )
    }

    /// 起きることを時刻の順に返す。そろわないときは complete を入れない。
    /// Reduce Motion のときは、インクを出し始めたとき（0 秒）に press、出しきったとき（0.2 秒）にそろえば complete
    static func events(reduceMotion: Bool, isComplete: Bool) -> [(time: TimeInterval, event: Event)] {
        var events: [(time: TimeInterval, event: Event)] = [(reduceMotion ? 0 : pressTime, .press)]
        if isComplete {
            events.append((reduceMotion ? reduceMotionFadeDuration : duration, .complete))
        }
        events.append((duration, .finish))
        return events
    }

    /// time が from から to までのどこにあるか（0〜1）
    private static func progress(_ time: TimeInterval, from start: TimeInterval, to end: TimeInterval) -> Double {
        guard end > start else {
            return time >= end ? 1 : 0
        }
        return min(max((time - start) / (end - start), 0), 1)
    }
}
