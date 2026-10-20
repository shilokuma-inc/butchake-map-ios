//
//  FontLicenseTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import Testing

/// 設定から開く書体のライセンス
struct FontLicenseTests {
    /// 3 つの書体のライセンス文がバンドルから読め、SIL Open Font License 1.1 の全文になっている
    @Test(arguments: FontLicense.allCases)
    func licenseTextLoadsFromBundle(font: FontLicense) throws {
        let text = try #require(font.licenseText(), "\(font.licenseFileName).txt が読めない")
        #expect(text.contains("SIL OPEN FONT LICENSE Version 1.1"))
        #expect(text.contains("Copyright"))
        // 全文（前文・許可・条件・終了・免責）が入っている
        #expect(text.contains("DISCLAIMER"))
    }

    /// 書体の名前とライセンス文のファイルが重ならない
    @Test
    func familyNamesAndFilesAreUnique() {
        #expect(Set(FontLicense.allCases.map(\.familyName)).count == FontLicense.allCases.count)
        #expect(Set(FontLicense.allCases.map(\.licenseFileName)).count == FontLicense.allCases.count)
    }
}
