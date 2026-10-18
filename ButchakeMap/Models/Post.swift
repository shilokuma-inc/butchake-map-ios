//
//  Post.swift
//  ButchakeMap
//

import Foundation

/// マイ三大の投稿
nonisolated struct Post: Identifiable, Codable, Hashable, Sendable {
    /// 1 投稿あたりのスポット数
    static let spotCount = 3

    var id = UUID()
    var authorName: String
    var authorType: AuthorType
    var title: String
    var prefecture: String
    var city: String
    var category: Category
    /// 要素数は spotCount（order 1, 2, 3 の順）
    var spots: [Spot]
    var likeCount: Int
    var starCount: Int
    var isLiked = false
    var isStarred = false
    var createdAt = Date()
    var isDraft = false

    /// 「都道府県 市区町村」の表示用文字列
    var area: String {
        [prefecture, city].filter { !$0.isEmpty }.joined(separator: " ")
    }

    /// カードのサムネイルに出す写真。写真のあるスポットのうち order が最も小さいもの（無ければ nil）
    var coverPhotoData: Data? {
        spots.sorted { $0.order < $1.order }.first { $0.photoData != nil }?.photoData
    }

    /// 入力前の空の下書き。スポットは order 1〜3 の空の枠を持つ
    static func newDraft(authorName: String, authorType: AuthorType = .traveler) -> Self {
        Self(
            authorName: authorName,
            authorType: authorType,
            title: "",
            prefecture: "",
            city: "",
            category: .gourmet,
            spots: (1...spotCount).map { Spot.empty(order: $0) },
            likeCount: 0,
            starCount: 0,
            isDraft: true
        )
    }
}
