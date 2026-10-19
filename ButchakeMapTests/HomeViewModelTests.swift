//
//  HomeViewModelTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import Foundation
import Testing

struct HomeViewModelTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let day: TimeInterval = 60 * 60 * 24

    private func post(
        title: String,
        daysAgo: Double,
        likes: Int = 0,
        stars: Int = 0,
        isDraft: Bool = false
    ) -> Post {
        Post(
            authorName: "テスト",
            authorType: .local,
            title: title,
            prefecture: "東京都",
            city: "千代田区",
            category: .gourmet,
            spots: (1...Post.spotCount).map { Spot.empty(order: $0) },
            likeCount: likes,
            starCount: stars,
            createdAt: now.addingTimeInterval(-daysAgo * day),
            isDraft: isDraft
        )
    }

    @Test
    func weeklyPicksAreRecentPublishedPostsNewestFirst() {
        let repository = MockDataRepository(posts: [
            post(title: "3日前", daysAgo: 3),
            post(title: "8日前", daysAgo: 8),
            post(title: "1日前", daysAgo: 1),
            post(title: "下書き", daysAgo: 0, isDraft: true),
            post(title: "ちょうど7日前", daysAgo: 7)
        ])
        let titles = HomeViewModel(repository: repository).weeklyPicks(now: now).map(\.title)
        #expect(titles == ["1日前", "3日前", "ちょうど7日前"])
    }

    @Test
    func weeklyPicksAreLimited() {
        let repository = MockDataRepository(posts: (0..<8).map { post(title: "\($0)", daysAgo: Double($0) / 2) })
        #expect(HomeViewModel(repository: repository).weeklyPicks(now: now).count == HomeViewModel.carouselLimit)
    }

    @Test
    func trendingIsOrderedByLikesPlusStarsAndExcludesDrafts() {
        let repository = MockDataRepository(posts: [
            post(title: "10", daysAgo: 1, likes: 5, stars: 5),
            post(title: "30", daysAgo: 2, likes: 10, stars: 20),
            post(title: "下書き", daysAgo: 0, likes: 999, isDraft: true),
            post(title: "10・新しい", daysAgo: 0, likes: 10),
            post(title: "20", daysAgo: 3, likes: 20)
        ])
        let titles = HomeViewModel(repository: repository).trendingPosts.map(\.title)
        #expect(titles == ["30", "20", "10・新しい", "10"])
    }

    @Test
    func trendingIsLimited() {
        let repository = MockDataRepository(posts: (0..<8).map { post(title: "\($0)", daysAgo: 1, likes: $0) })
        let trending = HomeViewModel(repository: repository).trendingPosts
        #expect(trending.count == HomeViewModel.carouselLimit)
        #expect(trending.first?.title == "7")
    }

    @Test
    func feedShowsAllPublishedPostsNewestFirst() {
        let repository = MockDataRepository(posts: [
            post(title: "古い", daysAgo: 30),
            post(title: "下書き", daysAgo: 0, isDraft: true),
            post(title: "新しい", daysAgo: 1)
        ])
        #expect(HomeViewModel(repository: repository).feedPosts.map(\.title) == ["新しい", "古い"])
    }

    @Test
    func toggleLikeAndStarGoThroughRepository() throws {
        let target = post(title: "対象", daysAgo: 1, likes: 3, stars: 1)
        let repository = MockDataRepository(posts: [target])
        let viewModel = HomeViewModel(repository: repository)

        viewModel.toggleLike(target)
        viewModel.toggleStar(target)

        let updated = try #require(repository.post(id: target.id))
        #expect(updated.isLiked)
        #expect(updated.likeCount == 4)
        #expect(updated.isStarred)
        #expect(updated.starCount == 2)
        #expect(viewModel.feedPosts.first?.isLiked == true)
    }

    @Test
    func deletedPostDisappearsFromEverySection() {
        let deleted = post(title: "消える", daysAgo: 1, likes: 10)
        let kept = post(title: "残る", daysAgo: 2)
        let repository = MockDataRepository(posts: [deleted, kept], currentUserName: "テスト")
        let viewModel = HomeViewModel(repository: repository)
        #expect(viewModel.feedPosts.count == 2)

        repository.delete(postID: deleted.id)

        #expect(viewModel.weeklyPicks(now: now).map(\.title) == ["残る"])
        #expect(viewModel.trendingPosts.map(\.title) == ["残る"])
        #expect(viewModel.feedPosts.map(\.title) == ["残る"])
    }

    @Test
    func postTurnedIntoDraftDisappearsFromEverySection() throws {
        let target = post(title: "下書きに戻す", daysAgo: 1, likes: 10)
        let repository = MockDataRepository(posts: [target], currentUserName: "テスト")
        let viewModel = HomeViewModel(repository: repository)
        #expect(viewModel.feedPosts.count == 1)

        // 公開済みの投稿は下書きに戻せないので、同じ ID の下書きに置き換えて確かめる
        repository.delete(postID: target.id)
        try repository.saveDraft(target, isNew: true)

        #expect(viewModel.weeklyPicks(now: now).isEmpty)
        #expect(viewModel.trendingPosts.isEmpty)
        #expect(viewModel.feedPosts.isEmpty)
    }

    @Test
    func initialMockDataFillsBothCarousels() {
        let viewModel = HomeViewModel(repository: MockDataRepository(posts: MockData.posts(now: now)))
        #expect(!viewModel.weeklyPicks(now: now).isEmpty)
        #expect(!viewModel.trendingPosts.isEmpty)
    }
}
