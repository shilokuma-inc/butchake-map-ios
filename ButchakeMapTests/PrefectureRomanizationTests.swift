//
//  PrefectureRomanizationTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import Testing

/// 都道府県のローマ字（駅名標の英字の行。Discussion #77 の Q6）
struct PrefectureRomanizationTests {
    /// 47 都道府県すべてに、空でない ASCII の大文字だけのローマ字がある
    @Test(arguments: Prefecture.allCases)
    func romanizedNameIsUppercaseASCII(prefecture: Prefecture) {
        let name = prefecture.romanizedName
        #expect(!name.isEmpty, "\(prefecture.rawValue) のローマ字が空")
        #expect(name.unicodeScalars.allSatisfy { ("A"..."Z").contains($0) }, "\(prefecture.rawValue) のローマ字「\(name)」に大文字の英字以外がある")
    }

    /// 47 件のローマ字が重ならない
    @Test
    func romanizedNamesAreUnique() {
        #expect(Prefecture.allCases.count == 47)
        #expect(Set(Prefecture.allCases.map(\.romanizedName)).count == 47)
    }

    /// 長音の記号を付けないヘボン式（例: 東京都 → TOKYO、大阪府 → OSAKA、兵庫県 → HYOGO、高知県 → KOCHI、大分県 → OITA）
    @Test
    func romanizationFollowsHepburnWithoutMacrons() {
        #expect(Prefecture.hokkaido.romanizedName == "HOKKAIDO")
        #expect(Prefecture.tokyo.romanizedName == "TOKYO")
        #expect(Prefecture.osaka.romanizedName == "OSAKA")
        #expect(Prefecture.kyoto.romanizedName == "KYOTO")
        #expect(Prefecture.hyogo.romanizedName == "HYOGO")
        #expect(Prefecture.kochi.romanizedName == "KOCHI")
        #expect(Prefecture.oita.romanizedName == "OITA")
        #expect(Prefecture.ishikawa.romanizedName == "ISHIKAWA")
    }
}
