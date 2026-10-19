//
//  SearchViewModelTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import Foundation
import Testing

struct SearchViewModelTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func post(
        title: String,
        spotNames: [String] = ["スポットA", "スポットB", "スポットC"],
        prefecture: String = "東京都",
        daysAgo: Double = 1,
        isDraft: Bool = false,
        // `Category` は Objective-C ランタイムの型と曖昧になり引数の型に書けないので、カテゴリはクロージャで変える
        configure: (inout Post) -> Void = { _ in }
    ) -> Post {
        var post = Post(
            authorName: "テスト",
            authorType: .local,
            title: title,
            prefecture: prefecture,
            city: "",
            category: .gourmet,
            spots: spotNames.enumerated().map { index, name in
                Spot(order: index + 1, name: name, address: "", recommendation: "")
            },
            likeCount: 0,
            starCount: 0,
            createdAt: now.addingTimeInterval(-daysAgo * 60 * 60 * 24),
            isDraft: isDraft
        )
        configure(&post)
        return post
    }

    private func titles(_ posts: [Post], _ filter: SearchFilter) -> [String] {
        SearchViewModel(repository: MockDataRepository(posts: posts)).results(for: filter).map(\.title)
    }

    @Test
    func emptyFilterShowsAllPublishedPostsNewestFirst() {
        let posts = [
            post(title: "古い", daysAgo: 3),
            post(title: "新しい", daysAgo: 1),
            post(title: "中くらい", daysAgo: 2)
        ]
        #expect(SearchFilter().isEmpty)
        #expect(titles(posts, SearchFilter()) == ["新しい", "中くらい", "古い"])
    }

    @Test
    func draftsAreNeverIncluded() {
        let posts = [
            post(title: "公開の寿司"),
            post(title: "下書きの寿司", isDraft: true)
        ]
        #expect(titles(posts, SearchFilter()) == ["公開の寿司"])
        #expect(titles(posts, SearchFilter(keyword: "寿司")) == ["公開の寿司"])
    }

    @Test
    func keywordMatchesTitle() {
        let posts = [post(title: "金沢の三大回転寿司"), post(title: "京都の朝さんぽ")]
        #expect(titles(posts, SearchFilter(keyword: "回転寿司")) == ["金沢の三大回転寿司"])
    }

    @Test
    func keywordMatchesSpotName() {
        let posts = [
            post(title: "朝さんぽ", spotNames: ["伏見稲荷大社", "哲学の道", "下鴨神社"]),
            post(title: "夕景")
        ]
        #expect(titles(posts, SearchFilter(keyword: "哲学")) == ["朝さんぽ"])
    }

    @Test
    func keywordWithoutMatchReturnsNothing() {
        let posts = [post(title: "金沢の三大回転寿司")]
        #expect(titles(posts, SearchFilter(keyword: "ラーメン")).isEmpty)
    }

    @Test
    func keywordIgnoresCaseAndWidthButNotDakuten() {
        let posts = [post(title: "Sushi Night", spotNames: ["パフェテリア", "はし", "カフェ"])]
        #expect(titles(posts, SearchFilter(keyword: "SUSHI")) == ["Sushi Night"])
        #expect(titles(posts, SearchFilter(keyword: "ｓｕｓｈｉ")) == ["Sushi Night"])
        #expect(titles(posts, SearchFilter(keyword: "ﾊﾟﾌｪ")) == ["Sushi Night"])
        #expect(titles(posts, SearchFilter(keyword: "ばし")).isEmpty)
    }

    @Test
    func keywordTermsSeparatedBySpacesMustAllMatch() {
        let posts = [
            post(title: "金沢の三大回転寿司", daysAgo: 1),
            post(title: "札幌の三大寿司", daysAgo: 2),
            post(title: "金沢の夕景", spotNames: ["寿司屋の屋上", "兼六園", "ひがし茶屋街"], daysAgo: 3)
        ]
        #expect(titles(posts, SearchFilter(keyword: " 金沢　寿司 ")) == ["金沢の三大回転寿司", "金沢の夕景"])
        #expect(SearchFilter(keyword: " 　 ").isEmpty)
    }

    @Test
    func prefectureFilter() {
        let posts = [
            post(title: "石川", prefecture: "石川県"),
            post(title: "北海道", prefecture: "北海道")
        ]
        #expect(titles(posts, SearchFilter(prefecture: "石川県")) == ["石川"])
    }

    @Test
    func categoryFilterMatchesAnySelectedCategory() {
        let posts = [
            post(title: "グルメ", daysAgo: 1),
            post(title: "絶景", daysAgo: 2) { $0.category = .scenery },
            post(title: "穴場", daysAgo: 3) { $0.category = .hiddenGem }
        ]
        #expect(titles(posts, SearchFilter(categories: [.scenery])) == ["絶景"])
        #expect(titles(posts, SearchFilter(categories: [.gourmet, .hiddenGem])) == ["グルメ", "穴場"])
    }

    @Test
    func toggleCategoryAddsAndRemoves() {
        var filter = SearchFilter()
        filter.toggle(.gourmet)
        filter.toggle(.scenery)
        #expect(filter.categories == [.gourmet, .scenery])
        filter.toggle(.gourmet)
        #expect(filter.categories == [.scenery])
    }

    @Test
    func allConditionsAreCombined() {
        let posts = [
            post(title: "金沢の寿司", prefecture: "石川県"),
            post(title: "金沢の絶景寿司", prefecture: "石川県") { $0.category = .scenery },
            post(title: "札幌の寿司", prefecture: "北海道"),
            post(title: "金沢のおでん", prefecture: "石川県")
        ]
        let filter = SearchFilter(keyword: "寿司", prefecture: "石川県", categories: [.gourmet])
        #expect(titles(posts, filter) == ["金沢の寿司"])
    }

    @Test
    func prefecturesComeFromPublishedPostsByCount() {
        let posts = [
            post(title: "1", prefecture: "京都府", daysAgo: 1),
            post(title: "2", prefecture: "北海道", daysAgo: 2),
            post(title: "3", prefecture: "石川県", daysAgo: 3),
            post(title: "4", prefecture: "石川県", daysAgo: 4),
            post(title: "下書き", prefecture: "沖縄県", daysAgo: 0, isDraft: true),
            post(title: "未入力", prefecture: "", daysAgo: 5)
        ]
        let viewModel = SearchViewModel(repository: MockDataRepository(posts: posts))
        #expect(viewModel.prefectures == ["石川県", "京都府", "北海道"])
    }

    @Test
    func toggleLikeAndStarGoThroughRepository() throws {
        let target = post(title: "対象")
        let repository = MockDataRepository(posts: [target])
        let viewModel = SearchViewModel(repository: repository)

        viewModel.toggleLike(target)
        viewModel.toggleStar(target)

        let updated = try #require(repository.post(id: target.id))
        #expect(updated.isLiked && updated.likeCount == 1)
        #expect(updated.isStarred && updated.starCount == 1)
        #expect(viewModel.results(for: SearchFilter()).first?.isLiked == true)
    }

    @Test
    func deletedPostDisappearsFromResultsAndPrefectures() {
        let deleted = post(title: "消える寿司", prefecture: "石川県")
        let kept = post(title: "残る寿司")
        let repository = MockDataRepository(posts: [deleted, kept], currentUserName: "テスト")
        let viewModel = SearchViewModel(repository: repository)
        #expect(viewModel.results(for: SearchFilter(keyword: "寿司")).count == 2)

        repository.delete(postID: deleted.id)

        #expect(viewModel.results(for: SearchFilter(keyword: "寿司")).map(\.title) == ["残る寿司"])
        #expect(viewModel.prefectures == ["東京都"])
    }

    @Test
    func postTurnedIntoDraftDisappearsFromResults() throws {
        let target = post(title: "下書きに戻す寿司", prefecture: "石川県")
        let repository = MockDataRepository(posts: [target], currentUserName: "テスト")
        let viewModel = SearchViewModel(repository: repository)

        // 公開済みの投稿は下書きに戻せないので、同じ ID の下書きに置き換えて確かめる
        repository.delete(postID: target.id)
        try repository.saveDraft(target, isNew: true)

        #expect(viewModel.results(for: SearchFilter()).isEmpty)
        #expect(viewModel.results(for: SearchFilter(keyword: "寿司")).isEmpty)
        #expect(viewModel.prefectures.isEmpty)
    }
}
