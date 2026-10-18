//
//  SearchViewModel.swift
//  ButchakeMap
//
//  検索の絞り込み。投稿は持たず、毎回 MockDataRepository から引く（他の画面と同期させるため）。
//  検索条件は画面の @State に SearchFilter として持ち、results(for:) に渡す
//

import Foundation

/// 検索条件。すべて空なら絞り込まない
struct SearchFilter: Equatable {
    /// フリーワード。空白（全角を含む）で区切った語をすべて含む投稿に絞る
    var keyword = ""
    /// nil ならすべての都道府県
    var prefecture: String?
    /// 選んだカテゴリのどれかに当てはまる投稿に絞る。空ならすべてのカテゴリ
    var categories: Set<Category> = []

    /// フリーワードを空白で区切った語
    var keywordTerms: [String] {
        keyword.split(whereSeparator: \.isWhitespace).map(String.init)
    }

    var isEmpty: Bool {
        keywordTerms.isEmpty && prefecture == nil && categories.isEmpty
    }

    /// カテゴリの選択を切り替える（複数選択）
    mutating func toggle(_ category: Category) {
        if categories.contains(category) {
            categories.remove(category)
        } else {
            categories.insert(category)
        }
    }
}

struct SearchViewModel {
    let repository: MockDataRepository

    /// 都道府県の候補: 公開済みの投稿に出てくる都道府県を、投稿の多い順に（同数なら新しい投稿に出てくる順）
    var prefectures: [String] {
        let names = repository.publishedPosts.map(\.prefecture).filter { !$0.isEmpty }
        var counts: [String: Int] = [:]
        var firstIndexes: [String: Int] = [:]
        for (index, name) in names.enumerated() {
            counts[name, default: 0] += 1
            if firstIndexes[name] == nil {
                firstIndexes[name] = index
            }
        }
        return counts.keys.sorted { lhs, rhs in
            counts[lhs] == counts[rhs]
                ? firstIndexes[lhs, default: 0] < firstIndexes[rhs, default: 0]
                : counts[lhs, default: 0] > counts[rhs, default: 0]
        }
    }

    /// 条件に当てはまる公開済みの投稿（新しい順）。条件が空ならすべて
    func results(for filter: SearchFilter) -> [Post] {
        repository.publishedPosts.filter { Self.matches($0, filter: filter) }
    }

    func toggleLike(_ post: Post) {
        repository.toggleLike(postID: post.id)
    }

    func toggleStar(_ post: Post) {
        repository.toggleStar(postID: post.id)
    }

    static func matches(_ post: Post, filter: SearchFilter) -> Bool {
        if let prefecture = filter.prefecture, post.prefecture != prefecture {
            return false
        }
        if !filter.categories.isEmpty, !filter.categories.contains(post.category) {
            return false
        }
        return filter.keywordTerms.allSatisfy { term in
            contains(post.title, term) || post.spots.contains { contains($0.name, term) }
        }
    }

    /// 大文字小文字と全角・半角（英数・カナ）を区別せずに部分一致させる。
    /// 濁点の有無（は / ば）やひらがな・カタカナは区別する
    static func contains(_ text: String, _ term: String) -> Bool {
        text.precomposedStringWithCompatibilityMapping.range(
            of: term.precomposedStringWithCompatibilityMapping,
            options: [.caseInsensitive, .widthInsensitive],
            locale: .current
        ) != nil
    }
}
