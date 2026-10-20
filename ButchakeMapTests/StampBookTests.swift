//
//  StampBookTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import Foundation
import Testing

/// ホームのスタンプ帳（自分の今月の投稿数。Discussion #77 の Q1）
struct StampBookTests {
    private let me = "わたし"
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        return calendar
    }()

    private func date(_ month: Int, _ day: Int, hour: Int = 12, minute: Int = 0) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute)))
    }

    private func post(author: String, city: String = "金沢市", createdAt: Date, isDraft: Bool = false) -> Post {
        var post = Post.newDraft(authorName: author)
        post.prefecture = "石川県"
        post.city = city
        post.createdAt = createdAt
        post.isDraft = isDraft
        return post
    }

    private func viewModel(_ posts: [Post]) -> HomeViewModel {
        HomeViewModel(repository: MockDataRepository(posts: posts, currentUserName: me))
    }

    /// 今月 1 日 0 時から数え、先月の最後の瞬間の投稿は数えない
    @Test
    func countsFromStartOfMonth() throws {
        let now = try date(10, 20)
        let book = viewModel([
            post(author: me, createdAt: try date(10, 1, hour: 0)),
            post(author: me, createdAt: try date(9, 30, hour: 23, minute: 59)),
            post(author: me, createdAt: try date(10, 19))
        ]).stampBook(now: now, calendar: calendar)
        #expect(book.count == 2)
    }

    /// 下書きとほかの人の投稿は数えない
    @Test
    func ignoresDraftsAndOthers() throws {
        let now = try date(10, 20)
        let book = viewModel([
            post(author: me, createdAt: try date(10, 5), isDraft: true),
            post(author: "ほかの人", createdAt: try date(10, 6)),
            post(author: me, createdAt: try date(10, 7))
        ]).stampBook(now: now, calendar: calendar)
        #expect(book.count == 1)
        #expect(book.stamps.count == 1)
    }

    /// 今月の投稿が無ければ 0 こで、スタンプも無い
    @Test
    func emptyWhenNoPostsThisMonth() throws {
        let book = viewModel([post(author: me, createdAt: try date(9, 1))]).stampBook(now: try date(10, 20), calendar: calendar)
        #expect(book == StampBook(count: 0, stamps: []))
    }

    /// スタンプは今月の新しい順に 3 こまで（日付は「M.d」、真ん中は市区町村、空なら都道府県）。数は全部を数える
    @Test
    func stampsAreNewestThreeOfMonth() throws {
        let book = viewModel([
            post(author: me, city: "横浜市", createdAt: try date(10, 2)),
            post(author: me, city: "金沢市", createdAt: try date(10, 18)),
            post(author: me, city: "", createdAt: try date(10, 9)),
            post(author: me, city: "札幌市", createdAt: try date(10, 12))
        ]).stampBook(now: try date(10, 20), calendar: calendar)
        #expect(book.count == 4)
        #expect(book.stamps.map(\.date) == ["10.18", "10.12", "10.9"])
        #expect(book.stamps.map(\.place) == ["金沢市", "札幌市", "石川県"])
    }

    /// 公開した直後に数え直すと、数が 1 つ増える
    @Test
    func publishingIncreasesCount() throws {
        let repository = MockDataRepository(posts: [], currentUserName: me)
        let viewModel = HomeViewModel(repository: repository)
        #expect(viewModel.stampBook().stamps.isEmpty)
        var draft = Post.newDraft(authorName: me)
        draft.title = "テスト"
        draft.prefecture = "石川県"
        try repository.publish(draft, isNew: true)
        #expect(viewModel.stampBook().count == 1)
    }
}
