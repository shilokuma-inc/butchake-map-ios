//
//  DepartureBoardFlapTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import Foundation
import Testing

/// 発車標の札がパタパタ回る動き（いいねの件数）のロジック
@MainActor
struct DepartureBoardFlapTests {
    // MARK: 桁ごとの前後の数字

    /// 件数の変化（前 → 後）
    nonisolated struct Change: Sendable, CustomTestStringConvertible {
        let from: Int
        let to: Int

        var testDescription: String {
            "\(from) → \(to)"
        }
    }

    nonisolated static let slotCases: [(change: Change, slots: [DepartureBoardFlapSlot])] = [
        // 1 の位だけ変わる
        (Change(from: 128, to: 129), [.init(from: "1", to: "1"), .init(from: "2", to: "2"), .init(from: "8", to: "9")]),
        // 繰り上がりで 2 桁変わる
        (Change(from: 129, to: 130), [.init(from: "1", to: "1"), .init(from: "2", to: "3"), .init(from: "9", to: "0")]),
        // 繰り下がり
        (Change(from: 130, to: 129), [.init(from: "1", to: "1"), .init(from: "3", to: "2"), .init(from: "0", to: "9")]),
        // 桁が増える（上の桁は前が無い）
        (Change(from: 9, to: 10), [.init(from: nil, to: "1"), .init(from: "9", to: "0")]),
        (Change(from: 99, to: 100), [.init(from: nil, to: "1"), .init(from: "9", to: "0"), .init(from: "9", to: "0")]),
        // 桁が減る（上の桁は後が無い）
        (Change(from: 10, to: 9), [.init(from: "1", to: nil), .init(from: "0", to: "9")]),
        (Change(from: 100, to: 99), [.init(from: "1", to: nil), .init(from: "0", to: "9"), .init(from: "0", to: "9")]),
        (Change(from: 0, to: 1), [.init(from: "0", to: "1")]),
        // 変わらない
        (Change(from: 42, to: 42), [.init(from: "4", to: "4"), .init(from: "2", to: "2")])
    ]

    /// 前後の数字を 1 の位でそろえて桁ごとに対応させ、桁の少ない方の上の桁は nil にする
    @Test(arguments: slotCases)
    func slotsAlignOnesPlace(change: Change, slots: [DepartureBoardFlapSlot]) {
        #expect(DepartureBoardFlap.slots(from: change.from, to: change.to) == slots)
    }

    nonisolated static let turningCases: [(change: Change, turning: [Bool])] = [
        (Change(from: 128, to: 129), [false, false, true]),
        (Change(from: 129, to: 130), [false, true, true]),
        (Change(from: 129, to: 128), [false, false, true]),
        (Change(from: 9, to: 10), [true, true]),
        (Change(from: 10, to: 9), [true, true]),
        (Change(from: 1_099, to: 1_100), [false, true, true, true]),
        (Change(from: 5, to: 5), [false])
    ]

    /// 変わった桁だけを回す
    @Test(arguments: turningCases)
    func onlyChangedDigitsTurn(change: Change, turning: [Bool]) {
        #expect(DepartureBoardFlap.slots(from: change.from, to: change.to).map(\.turns) == turning)
    }

    // MARK: 並べる桁

    /// 回る前は前の数字の桁だけ、回っている間は両方の桁、止まったら新しい数字の桁だけを並べる（9 → 10）
    @Test
    func visibleSlotsWhenDigitsIncrease() {
        let slots = DepartureBoardFlap.slots(from: 9, to: 10)
        #expect(DepartureBoardFlap.visibleSlots(slots, progress: 0).map(\.from) == ["9"])
        #expect(DepartureBoardFlap.visibleSlots(slots, progress: 0.5).count == 2)
        #expect(DepartureBoardFlap.visibleSlots(slots, progress: 1).map(\.to) == ["1", "0"])
    }

    /// 桁が減るとき（10 → 9）は、止まったら上の桁の札を外す
    @Test
    func visibleSlotsWhenDigitsDecrease() {
        let slots = DepartureBoardFlap.slots(from: 10, to: 9)
        #expect(DepartureBoardFlap.visibleSlots(slots, progress: 0).map(\.from) == ["1", "0"])
        #expect(DepartureBoardFlap.visibleSlots(slots, progress: 0.5).count == 2)
        #expect(DepartureBoardFlap.visibleSlots(slots, progress: 1).map(\.to) == ["9"])
    }

    /// 桁数が変わらなければ、いつもすべての桁を並べる
    @Test(arguments: [0.0, 0.3, 1.0])
    func visibleSlotsKeepAllDigitsWhenCountIsSame(progress: Double) {
        let slots = DepartureBoardFlap.slots(from: 129, to: 130)
        #expect(DepartureBoardFlap.visibleSlots(slots, progress: progress) == slots)
    }

    // MARK: 段ごとの進み具合

    /// 前半で上半分が落ち、後半で下半分が開く
    @Test
    func stageProgressSplitsIntoTwoStages() {
        #expect(DepartureBoardFlap.stageProgress(0) == (0, 0))
        #expect(DepartureBoardFlap.stageProgress(0.5) == (1, 0))
        #expect(DepartureBoardFlap.stageProgress(1) == (1, 1))
        let middleOfSecond = DepartureBoardFlap.stageProgress(0.75)
        #expect(middleOfSecond.top == 1)
        #expect(middleOfSecond.bottom > 0 && middleOfSecond.bottom < 1)
    }

    /// 段ごとに easeIn（初めはゆっくり）なので、段の半ばでは等速より進みが遅い
    @Test
    func stageProgressEasesIn() {
        let quarter = DepartureBoardFlap.stageProgress(0.25)
        #expect(quarter.top > 0 && quarter.top < 0.5)
        #expect(quarter.bottom == 0)
    }

    /// 範囲の外や数でない値は、0〜1 にそろえる（数でなければ止まった札）
    @Test
    func stageProgressClampsOutOfRange() {
        #expect(DepartureBoardFlap.stageProgress(-1) == (0, 0))
        #expect(DepartureBoardFlap.stageProgress(2) == (1, 1))
        #expect(DepartureBoardFlap.stageProgress(.nan) == (1, 1))
    }

    // MARK: 時間

    /// ハートを 0.15 秒で塗ってから、札が 0.12 秒ずつ 2 段で回り、約 0.4 秒で止まる
    @Test
    func timingMatchesMotionSpec() {
        #expect(DepartureBoardFlap.heartFillDuration == 0.15)
        #expect(DepartureBoardFlap.stageDuration == 0.12)
        #expect(abs(DepartureBoardFlap.turnDuration - 0.24) < 0.000_1)
        #expect(abs(DepartureBoardFlap.totalDuration - 0.4) < 0.02)
        #expect(DepartureBoardFlap.crossfadeDuration == 0.15)
    }

    /// 押してからの時間に対して、ハートを塗る間は札が止まっていて、塗り終えてから回る
    @Test
    func turnProgressStartsAfterHeartFill() {
        #expect(DepartureBoardFlap.turnProgress(at: 0) == 0)
        #expect(DepartureBoardFlap.turnProgress(at: 0.15) == 0)
        #expect(abs(DepartureBoardFlap.turnProgress(at: 0.27) - 0.5) < 0.000_1)
        #expect(DepartureBoardFlap.turnProgress(at: 0.4) == 1)
        #expect(DepartureBoardFlap.turnProgress(at: .infinity) == 1)
    }

    /// ハートの塗りは 0.15 秒で終わる（easeOut なので半ばでは等速より進んでいる）
    @Test
    func heartFillEasesOut() {
        #expect(DepartureBoardFlap.heartFill(at: 0) == 0)
        #expect(DepartureBoardFlap.heartFill(at: 0.075) > 0.5)
        #expect(DepartureBoardFlap.heartFill(at: 0.15) == 1)
        #expect(DepartureBoardFlap.heartFill(at: 1) == 1)
    }
}
