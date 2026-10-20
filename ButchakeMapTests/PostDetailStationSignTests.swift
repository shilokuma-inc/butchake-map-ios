//
//  PostDetailStationSignTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import Foundation
import Testing

/// 投稿詳細の都市の駅名標と、駅のスタンプに出す文字
struct PostDetailStationSignTests {
    private func post(prefecture: String, city: String, createdAt: Date = Date()) -> Post {
        var post = Post.newDraft(authorName: "テスト")
        post.prefecture = prefecture
        post.city = city
        post.createdAt = createdAt
        return post
    }

    /// 大きな文字は市区町村、英字の行は都道府県のローマ字
    @Test
    func signShowsCityAndPrefectureRomanization() {
        let text = PostDetailViewModel.stationSignText(of: post(prefecture: "石川県", city: "金沢市"))
        #expect(text == .init(name: "金沢市", english: "ISHIKAWA"))
    }

    /// 市区町村が空なら、大きな文字に都道府県を出す
    @Test
    func signShowsPrefectureWhenCityIsEmpty() {
        let text = PostDetailViewModel.stationSignText(of: post(prefecture: "北海道", city: " "))
        #expect(text == .init(name: "北海道", english: "HOKKAIDO"))
    }

    /// 47 都道府県に無い名前なら、英字の行を出さない
    @Test
    func signHasNoEnglishForUnknownPrefecture() {
        let text = PostDetailViewModel.stationSignText(of: post(prefecture: "", city: "金沢市"))
        #expect(text == .init(name: "金沢市", english: nil))
    }

    /// スタンプの日付は投稿日の「M.d」（0 を付けない）
    @Test
    func stampDateIsMonthDotDay() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 9, hour: 23)))
        #expect(PostDetailViewModel.stampDate(of: post(prefecture: "石川県", city: "金沢市", createdAt: date), calendar: calendar) == "1.9")
    }

    /// スタンプの地名は市区町村、空なら都道府県
    @Test
    func stampPlaceFallsBackToPrefecture() {
        #expect(PostDetailViewModel.stampPlace(of: post(prefecture: "石川県", city: "金沢市")) == "金沢市")
        #expect(PostDetailViewModel.stampPlace(of: post(prefecture: "石川県", city: "")) == "石川県")
    }
}
