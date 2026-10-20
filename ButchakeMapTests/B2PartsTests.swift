//
//  B2PartsTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import CoreGraphics
import Testing

/// B-2 の部品（スタンプ・路線図の駅・発車標の数字）のロジック
@MainActor
struct B2PartsTests {
    // MARK: 部品の倍率

    /// 文字の大きさの設定による倍率は上限で止まり、上限より小さければそのまま
    @Test
    func partScaleIsClampedToMax() {
        #expect(B2PartScale.clamped(1, max: 2) == 1)
        #expect(B2PartScale.clamped(1.5, max: 2) == 1.5)
        #expect(B2PartScale.clamped(3.2, max: 2) == 2)
        #expect(B2PartScale.clamped(0.8, max: 2) == 0.8)
    }

    /// 倍率が 0 以下や数でないときは 1 にする（部品が消えないように）
    @Test
    func partScaleFallsBackToOneForInvalidValues() {
        #expect(B2PartScale.clamped(0, max: 2) == 1)
        #expect(B2PartScale.clamped(-1, max: 2) == 1)
        #expect(B2PartScale.clamped(.nan, max: 2) == 1)
        #expect(B2PartScale.clamped(.infinity, max: 2) == 1)
    }

    /// 文字の基の大きさに掛ける値は、上限までは 1、上限を超えたら「上限 ÷ 倍率」で、文字も部品と同じ倍率になる
    @Test
    func fontAdjustmentKeepsTextInProportion() {
        #expect(B2PartScale.fontAdjustment(1, max: 2) == 1)
        #expect(B2PartScale.fontAdjustment(0.8, max: 2) == 1)
        #expect(B2PartScale.fontAdjustment(4, max: 2) == 0.5)
        #expect(B2PartScale.fontAdjustment(0, max: 2) == 1)
        let scale: CGFloat = 3.2
        #expect(abs(B2PartScale.fontAdjustment(scale, max: 2) * scale - 2) < 0.0001)
    }

    // MARK: スタンプの書体

    /// 文字がすべてスタンプの書体にあればスタンプの書体、無ければ見出しの書体を選ぶ
    @Test
    func stampTypefaceFollowsCoverage() {
        #expect(StampTypeface.forText("済") { _ in true } == .stamp)
        #expect(StampTypeface.forText("金沢") { _ in false } == .heading)
    }

    /// 同梱のサブセットで: 決まった文字・日付はスタンプの書体、市区町村の名前は見出しの書体
    @Test(arguments: [
        ("済", StampTypeface.stamp),
        ("公開", .stamp),
        ("10.18", .stamp),
        ("金沢", .heading),
        ("横浜", .heading),
        ("済み", .heading)
    ])
    func stampTypefaceWithBundledSubset(text: String, expected: StampTypeface) {
        #expect(StampTypeface.forText(text) == expected)
    }

    // MARK: 発車標の数字

    nonisolated static let digitCases: [(value: Int, digits: [String])] = [
        (128, ["1", "2", "8"]),
        (0, ["0"]),
        (7, ["7"]),
        (1_000, ["1", "0", "0", "0"]),
        (1_234_567, ["1", "2", "3", "4", "5", "6", "7"]),
        (-5, ["-", "5"])
    ]

    /// 数字を桁ごとの札に分ける（桁区切りの「,」は入らない）
    @Test(arguments: digitCases)
    func departureBoardDigits(value: Int, digits: [String]) {
        #expect(DepartureBoardNumber.digits(of: value) == digits)
    }

    /// とても大きな数も桁区切りなしで、すべての桁が札になる
    @Test
    func departureBoardDigitsOfMaxInt() {
        let digits = DepartureBoardNumber.digits(of: Int.max)
        #expect(digits.joined() == String(Int.max))
        #expect(digits.allSatisfy { $0.count == 1 && $0 != "," })
    }
}
