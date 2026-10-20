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

    /// スタンプ帳（Discussion #77 の Q1）: 自分が今月公開した投稿 1 つ = スタンプ 1 こ。
    /// 「今月」は端末のカレンダーとタイムゾーンの今月 1 日 0 時から。下書きとほかの人の投稿は数えない
    func stampBook(now: Date = Date(), calendar: Calendar = .current) -> StampBook {
        guard let month = calendar.dateInterval(of: .month, for: now) else {
            return StampBook(count: 0, stamps: [])
        }
        let posts = repository.myPosts
            .filter { month.contains($0.createdAt) }
            .sorted { $0.createdAt > $1.createdAt }
        let stamps = posts.prefix(StampBook.visibleStampLimit).map { post in
            StampBook.Stamp(
                id: post.id,
                date: PostDetailViewModel.stampDate(of: post, calendar: calendar),
                place: PostDetailViewModel.stampPlace(of: post)
            )
        }
        return StampBook(count: posts.count, stamps: Array(stamps))
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

/// ホームのスタンプ帳に出す内容
struct StampBook: Equatable {
    /// 押して見せるスタンプの数（新しい順）。その後ろに次の 1 こ分の空き欄を置く
    static let visibleStampLimit = 3

    /// 今月の自分の公開済みの投稿の数
    let count: Int
    /// 押して見せるスタンプ（今月の新しい順に visibleStampLimit こまで）
    let stamps: [Stamp]

    struct Stamp: Equatable, Identifiable {
        let id: Post.ID
        /// 上の小さな文字（投稿日の「M.d」）
        let date: String
        /// 真ん中の文字（市区町村、空なら都道府県）
        let place: String
    }
}
