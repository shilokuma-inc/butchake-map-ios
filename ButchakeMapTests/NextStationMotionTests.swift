//
//  NextStationMotionTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import Foundation
import Testing

/// 投稿詳細へ進むときの「次の駅へ」の動き（上の路線の帯の紺の丸）のロジック
@MainActor
struct NextStationMotionTests {
    // MARK: 段の時間

    /// 0.1 秒待ってから 0.35 秒で進み、0.45 秒で次の駅に着く。視差効果を減らすときは 0.2 秒のクロスフェード
    @Test
    func durationsMatchMotionSheet() {
        #expect(NextStationMotion.delay == 0.1)
        #expect(NextStationMotion.travelDuration == 0.35)
        #expect(abs(NextStationMotion.totalDuration - 0.45) < 1e-9)
        #expect(NextStationMotion.crossfadeDuration == 0.2)
    }

    /// ハプティクスは着いたとき（ふだんは 0.45 秒、視差効果を減らすときはクロスフェードを終えた 0.2 秒）に鳴らす
    @Test
    func arrivalDelayDependsOnReduceMotion() {
        #expect(NextStationMotion.arrivalDelay(reduceMotion: false) == NextStationMotion.totalDuration)
        #expect(NextStationMotion.arrivalDelay(reduceMotion: true) == NextStationMotion.crossfadeDuration)
    }

    // MARK: 紺の丸の進み具合

    /// 動き始める前（0.1 秒まで）は前の駅、0.45 秒で次の駅に着き、その後も次の駅のまま
    @Test(arguments: [(-1.0, 0.0), (0, 0), (0.05, 0), (0.1, 0), (0.45, 1), (0.6, 1), (10, 1)])
    func markerProgressIsClampedOutsideTravel(elapsed: TimeInterval, progress: Double) {
        #expect(NextStationMotion.markerProgress(at: elapsed) == progress)
    }

    /// 数でない時間では着いた位置にする（丸が途中で止まらないように）
    @Test
    func markerProgressFallsBackToArrivedForInvalidTime() {
        #expect(NextStationMotion.markerProgress(at: .nan) == 1)
        #expect(NextStationMotion.markerProgress(at: .infinity) == 1)
    }

    /// easeInOut なので、真ん中（0.275 秒）でちょうど半分、前半はゆっくり・後半もゆっくり
    @Test
    func markerProgressEasesInAndOut() {
        let middle = NextStationMotion.delay + NextStationMotion.travelDuration / 2
        #expect(abs(NextStationMotion.markerProgress(at: middle) - 0.5) < 0.001)
        // 1 割の時間では 1 割より進んでいない（ゆっくり出る）
        let early = NextStationMotion.delay + NextStationMotion.travelDuration * 0.1
        #expect(NextStationMotion.markerProgress(at: early) < 0.1)
        // 9 割の時間では 9 割より進んでいる（ゆっくり着く）
        let late = NextStationMotion.delay + NextStationMotion.travelDuration * 0.9
        #expect(NextStationMotion.markerProgress(at: late) > 0.9)
    }

    /// 時間が進むほど丸も進む（戻らない）
    @Test
    func markerProgressNeverGoesBack() {
        let samples = stride(from: 0.0, through: 0.5, by: 0.01).map { NextStationMotion.markerProgress(at: $0) }
        #expect(zip(samples, samples.dropFirst()).allSatisfy { $0 <= $1 })
    }

    /// モックのコマ（0.15 秒で帯の 3%、0.30 秒で 31%、0.45 秒で 50%）とほぼ同じ位置に来る
    @Test(arguments: [(0.0, 0.0), (0.15, 0.03), (0.30, 0.31), (0.45, 0.5)])
    func markerFractionMatchesMockFrames(elapsed: TimeInterval, fraction: Double) {
        let actual = NextStationMotion.markerFraction(progress: NextStationMotion.markerProgress(at: elapsed))
        #expect(abs(actual - fraction) < 0.02)
    }

    // MARK: 帯の位置

    /// 紺の丸は前の駅（左端）から次の駅（真ん中）まで進み、その先へは出ない
    @Test
    func markerFractionRunsFromDepartureToArrival() {
        #expect(NextStationMotion.markerFraction(progress: 0) == NextStationMotion.departureFraction)
        #expect(NextStationMotion.markerFraction(progress: 0.5) == 0.25)
        #expect(NextStationMotion.markerFraction(progress: 1) == NextStationMotion.arrivalFraction)
        #expect(NextStationMotion.markerFraction(progress: -1) == NextStationMotion.departureFraction)
        #expect(NextStationMotion.markerFraction(progress: 2) == NextStationMotion.arrivalFraction)
        #expect(NextStationMotion.markerFraction(progress: .nan) == NextStationMotion.arrivalFraction)
    }

    /// 帯の駅は前の駅・次の駅・その先の駅の 3 つで、出る駅と着く駅はその中にある
    @Test
    func stationsIncludeDepartureAndArrival() {
        #expect(NextStationMotion.stationFractions == [0, 0.5, 1])
        #expect(NextStationMotion.stationFractions.contains(NextStationMotion.departureFraction))
        #expect(NextStationMotion.stationFractions.contains(NextStationMotion.arrivalFraction))
    }

    // MARK: 視差効果を減らすとき

    /// 0 秒で見えず、0.1 秒で半分、0.2 秒で見えきる（easeInOut のクロスフェード）
    @Test
    func crossfadeOpacityRunsOverPointTwoSeconds() {
        #expect(NextStationMotion.crossfadeOpacity(at: 0) == 0)
        #expect(abs(NextStationMotion.crossfadeOpacity(at: 0.1) - 0.5) < 0.001)
        #expect(NextStationMotion.crossfadeOpacity(at: 0.2) == 1)
        #expect(NextStationMotion.crossfadeOpacity(at: 1) == 1)
        #expect(NextStationMotion.crossfadeOpacity(at: -1) == 0)
        #expect(NextStationMotion.crossfadeOpacity(at: .nan) == 1)
    }

    /// 視差効果を減らすときは、どのコマでも丸は次の駅にあり、不透明度だけが変わる
    @Test(arguments: [0.0, 0.1, 0.2, 0.45])
    func reduceMotionFramesKeepMarkerArrived(elapsed: TimeInterval) {
        let frame = NextStationMotion.frame(at: elapsed, reduceMotion: true)
        #expect(frame.markerProgress == 1)
        #expect(frame.contentOpacity == NextStationMotion.crossfadeOpacity(at: elapsed))
    }

    /// ふだんは中身を薄くせず、丸だけが進む
    @Test(arguments: [0.0, 0.1, 0.2, 0.3, 0.4, 0.45])
    func standardFramesKeepContentOpaque(elapsed: TimeInterval) {
        let frame = NextStationMotion.frame(at: elapsed, reduceMotion: false)
        #expect(frame.contentOpacity == 1)
        #expect(frame.markerProgress == NextStationMotion.markerProgress(at: elapsed))
    }

    // MARK: アニメーションの始まりと終わり

    /// 着く前は、ふだんは前の駅・視差効果を減らすときは見えない状態。着いたらどちらも同じ止まったコマ
    @Test
    func framesBeforeAndAfterArrival() {
        #expect(NextStationMotion.frame(hasArrived: false, reduceMotion: false) == NextStationFrame(markerProgress: 0, contentOpacity: 1))
        #expect(NextStationMotion.frame(hasArrived: false, reduceMotion: true) == NextStationFrame(markerProgress: 1, contentOpacity: 0))
        #expect(NextStationMotion.frame(hasArrived: true, reduceMotion: false) == .arrived)
        #expect(NextStationMotion.frame(hasArrived: true, reduceMotion: true) == .arrived)
    }

    /// 始まりと終わりのコマは、時間で決めたコマの 0 秒と着いたときに合う
    @Test(arguments: [false, true])
    func boundaryFramesMatchTimedFrames(reduceMotion: Bool) {
        let start = NextStationMotion.frame(hasArrived: false, reduceMotion: reduceMotion)
        #expect(start == NextStationMotion.frame(at: 0, reduceMotion: reduceMotion))
        let arrival = NextStationMotion.arrivalDelay(reduceMotion: reduceMotion)
        let end = NextStationMotion.frame(hasArrived: true, reduceMotion: reduceMotion)
        #expect(end == NextStationMotion.frame(at: arrival + 0.01, reduceMotion: reduceMotion))
    }
}
