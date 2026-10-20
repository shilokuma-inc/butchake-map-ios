//
//  HomeSectionTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import Foundation
import Testing

/// ホームの見出しの駅名標（前後のセクション）と、投稿カードのスタンプの年
struct HomeSectionTests {
    /// 駅名標の帯の前後は、並びの順の隣のセクション。先頭に前は無く、最後に次は無い
    @Test
    func sectionsLinkToNeighbors() {
        #expect(HomeSection.allCases == [.weeklyPicks, .trending, .latestPosts])
        #expect(HomeSection.weeklyPicks.previous == nil)
        #expect(HomeSection.weeklyPicks.next == .trending)
        #expect(HomeSection.trending.previous == .weeklyPicks)
        #expect(HomeSection.trending.next == .latestPosts)
        #expect(HomeSection.latestPosts.previous == .trending)
        #expect(HomeSection.latestPosts.next == nil)
    }

    /// 駅名標の英字の行は、翻訳しない大文字の英字
    @Test
    func englishLabelsAreUppercase() {
        for section in HomeSection.allCases {
            #expect(section.englishLabel == section.englishLabel.uppercased())
            #expect(!section.englishLabel.isEmpty)
        }
    }

    /// 投稿カードのスタンプの上の年は、投稿日の西暦の数字
    @Test
    func stampYearIsYearOfCreatedAt() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        var post = Post.newDraft(authorName: "テスト")
        post.createdAt = try #require(calendar.date(from: DateComponents(year: 2026, month: 12, day: 31, hour: 23)))
        #expect(PostCardView.stampYear(of: post, calendar: calendar) == "2026")
    }
}
