//
//  HomeViewModel.swift
//  ButchakeMap
//
//  ホームに出す投稿の選び方。投稿は持たず、毎回 MockDataRepository から引く（他の画面と同期させるため）
//

import Foundation

struct HomeViewModel {
    /// カルーセル 1 本に出す最大件数
    static let carouselLimit = 5
    /// 「今週のぶっちゃけ」に出す期間
    static let weeklyPeriod: TimeInterval = 60 * 60 * 24 * 7

    let repository: MockDataRepository

    /// 今週のぶっちゃけ: 直近 7 日に公開された投稿を新しい順に
    func weeklyPicks(now: Date = Date()) -> [Post] {
        let since = now.addingTimeInterval(-Self.weeklyPeriod)
        return Array(repository.publishedPosts.filter { $0.createdAt >= since }.prefix(Self.carouselLimit))
    }

    /// 急上昇: いいねとスターの合計が多い順に（同数なら新しい順）
    var trendingPosts: [Post] {
        let sorted = repository.publishedPosts.enumerated().sorted { lhs, rhs in
            let lhsScore = Self.score(lhs.element)
            let rhsScore = Self.score(rhs.element)
            return lhsScore == rhsScore ? lhs.offset < rhs.offset : lhsScore > rhsScore
        }
        return Array(sorted.map(\.element).prefix(Self.carouselLimit))
    }

    /// フィード: 公開済みの投稿をすべて新しい順に
    var feedPosts: [Post] {
        repository.publishedPosts
    }

    func toggleLike(_ post: Post) {
        repository.toggleLike(postID: post.id)
    }

    func toggleStar(_ post: Post) {
        repository.toggleStar(postID: post.id)
    }

    private static func score(_ post: Post) -> Int {
        post.likeCount + post.starCount
    }
}
