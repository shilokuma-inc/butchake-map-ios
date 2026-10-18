//
//  LocalizationTests.swift
//  ButchakeMapTests
//
//  表示言語（日本語・英語）の文言の抜けを検査する。
//  - リポジトリの ButchakeMap/Localizable.xcstrings（String Catalog）を #filePath からたどって読み、全キーに ja / en が translated で入っていること
//    （テストは Simulator で動くので、ビルドした Mac のリポジトリのファイルを読める）
//  - アプリのバンドルにコンパイルされた en.lproj / ja.lproj の Localizable.strings が同じキーを持つこと
//    （String Catalog で片方の言語が無いキーは、その言語の Localizable.strings から抜ける）
//  - コードの LocalizedStringResource（タブ・カテゴリ・投稿者属性・マイページの一覧・保存の結果など）が両方の言語にあること
//

@testable import ButchakeMap
import Foundation
import Testing

struct LocalizationTests {
    static let languages = ["en", "ja"]

    @Test
    func stringCatalogHasTranslatedJapaneseAndEnglishForEveryKey() throws {
        let catalog = try StringCatalog.load()

        #expect(catalog.sourceLanguage == "en")
        #expect(!catalog.strings.isEmpty)
        for (key, entry) in catalog.strings where entry.shouldTranslate != false {
            for language in Self.languages {
                let unit = entry.localizations?[language]?.stringUnit
                #expect(unit?.state == "translated", "「\(key)」の \(language) が translated ではない: \(unit?.state ?? "なし")")
                #expect(unit?.value.isEmpty == false, "「\(key)」の \(language) の文言が空")
            }
        }
    }

    @Test
    func compiledStringsHaveSameKeysInJapaneseAndEnglish() throws {
        let english = try Self.compiledKeys(language: "en")
        let japanese = try Self.compiledKeys(language: "ja")

        let missingJapanese = english.subtracting(japanese).sorted()
        let missingEnglish = japanese.subtracting(english).sorted()
        #expect(!english.isEmpty)
        #expect(missingJapanese.isEmpty, "日本語が無いキー: \(missingJapanese)")
        #expect(missingEnglish.isEmpty, "英語が無いキー: \(missingEnglish)")
    }

    @Test
    func compiledStringsMatchStringCatalog() throws {
        let catalogKeys = try Set(StringCatalog.load().strings.keys)

        for language in Self.languages {
            #expect(try Self.compiledKeys(language: language) == catalogKeys, "\(language) のビルド結果と String Catalog のキーが違う")
        }
    }

    @Test
    func resourcesUsedInCodeHaveJapaneseAndEnglish() throws {
        let keys = Self.codeResources.map(\.key)
        for language in Self.languages {
            let compiled = try Self.compiledKeys(language: language)
            for key in keys {
                #expect(compiled.contains(key), "「\(key)」の \(language) が無い")
            }
        }
    }

    // MARK: - Private

    /// 画面の外（enum の表示名など）で組み立てている文言
    private static var codeResources: [LocalizedStringResource] {
        let outcomes: [PostCreateViewModel.Outcome] = [
            .savedDraft,
            .published,
            .failed(.notFound),
            .failed(.alreadyPublished),
            .failed(.alreadyExists),
            .failed(.notMine)
        ]
        let fieldErrors: [PostCreateViewModel.FieldError] = [.required, .unselected, .tooLong(limit: 10)]
        return MainTab.allCases.map(\.title)
            + Category.allCases.map(\.displayName)
            + AuthorType.allCases.map(\.displayName)
            + ExternalMapApp.allCases.map(\.displayName)
            + MyPageSection.allCases.flatMap { [$0.title, $0.emptyTitle, $0.emptyDescription] }
            + outcomes.map(\.title)
            + outcomes.compactMap(\.message)
            + fieldErrors.map(\.message)
    }

    /// アプリのバンドルにある <言語>.lproj の Localizable.strings（と、複数形などの Localizable.stringsdict）のキー
    private static func compiledKeys(language: String) throws -> Set<String> {
        let bundle = Bundle(for: MockDataRepository.self)
        let stringsURL = try #require(
            bundle.url(forResource: "Localizable", withExtension: "strings", subdirectory: nil, localization: language),
            "\(language).lproj/Localizable.strings がアプリのバンドルに無い"
        )
        var keys = try Set(dictionary(at: stringsURL).keys)
        if let stringsdictURL = bundle.url(
            forResource: "Localizable",
            withExtension: "stringsdict",
            subdirectory: nil,
            localization: language
        ) {
            keys.formUnion(try dictionary(at: stringsdictURL).keys)
        }
        return keys
    }

    private static func dictionary(at url: URL) throws -> [String: Any] {
        let data = try Data(contentsOf: url)
        return try #require(
            PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            "\(url.lastPathComponent) を読めない"
        )
    }
}

/// Localizable.xcstrings のうち、検査に使う項目だけ読む
private struct StringCatalog: Decodable {
    struct Entry: Decodable {
        var shouldTranslate: Bool?
        var localizations: [String: Localization]?
    }

    struct Localization: Decodable {
        /// 複数形などの variations を使うキーでは nil（使うようになったら検査を広げる）
        var stringUnit: StringUnit?
    }

    struct StringUnit: Decodable {
        var state: String
        var value: String
    }

    var sourceLanguage: String
    var strings: [String: Entry]

    /// このファイル（ButchakeMapTests/LocalizationTests.swift）から 2 つ上がリポジトリのルート
    static let url = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appending(path: "ButchakeMap/Localizable.xcstrings")

    static func load() throws -> Self {
        try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
    }
}
