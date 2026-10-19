//
//  MyPageViewModelTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import Foundation
import Testing

struct MyPageViewModelTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let me = "自分"

    private func post(
        title: String,
        author: String? = nil,
        daysAgo: Double = 1,
        likes: Int = 0,
        isStarred: Bool = false,
        isDraft: Bool = false
    ) -> Post {
        Post(
            authorName: author ?? me,
            authorType: .traveler,
            title: title,
            prefecture: "東京都",
            city: "",
            category: .gourmet,
            spots: (1...Post.spotCount).map { Spot.empty(order: $0) },
            likeCount: likes,
            starCount: isStarred ? 1 : 0,
            isStarred: isStarred,
            createdAt: now.addingTimeInterval(-daysAgo * 60 * 60 * 24),
            isDraft: isDraft
        )
    }

    private func viewModel(_ posts: [Post], section: MyPageSection = .myPosts) -> MyPageViewModel {
        MyPageViewModel(repository: MockDataRepository(posts: posts, currentUserName: me), section: section)
    }

    @Test
    func myPostsAreOnlyMyPublishedPostsNewestFirst() {
        let viewModel = viewModel([
            post(title: "自分・古い", daysAgo: 3),
            post(title: "他人", author: "他人", daysAgo: 0),
            post(title: "自分の下書き", daysAgo: 0, isDraft: true),
            post(title: "自分・新しい", daysAgo: 1)
        ])
        #expect(viewModel.posts.map(\.title) == ["自分・新しい", "自分・古い"])
        #expect(viewModel.count(in: .myPosts) == 2)
    }

    @Test
    func savedAreOnlyStarredPublishedPosts() {
        let viewModel = viewModel(
            [
                post(title: "他人・スター", author: "他人", daysAgo: 2, isStarred: true),
                post(title: "他人・スターなし", author: "他人", daysAgo: 1),
                post(title: "自分・スター", daysAgo: 1, isStarred: true),
                post(title: "下書き・スター", daysAgo: 0, isStarred: true, isDraft: true)
            ],
            section: .saved
        )
        #expect(viewModel.posts.map(\.title) == ["自分・スター", "他人・スター"])
        #expect(viewModel.count(in: .saved) == 2)
    }

    @Test
    func draftsAreOnlyMyDrafts() {
        let viewModel = viewModel(
            [
                post(title: "自分の下書き・古い", daysAgo: 2, isDraft: true),
                post(title: "他人の下書き", author: "他人", daysAgo: 0, isDraft: true),
                post(title: "自分の公開済み", daysAgo: 0),
                post(title: "自分の下書き・新しい", daysAgo: 1, isDraft: true)
            ],
            section: .drafts
        )
        #expect(viewModel.posts.map(\.title) == ["自分の下書き・新しい", "自分の下書き・古い"])
    }

    @Test
    func switchingSectionChangesPosts() {
        var viewModel = viewModel([
            post(title: "公開", daysAgo: 1, isStarred: false),
            post(title: "保存", author: "他人", daysAgo: 1, isStarred: true),
            post(title: "下書き", daysAgo: 1, isDraft: true)
        ])
        #expect(viewModel.posts.map(\.title) == ["公開"])
        viewModel.section = .saved
        #expect(viewModel.posts.map(\.title) == ["保存"])
        viewModel.section = .drafts
        #expect(viewModel.posts.map(\.title) == ["下書き"])
    }

    @Test
    func everySectionIsEmptyWithoutPosts() {
        let viewModel = viewModel([])
        for section in MyPageSection.allCases {
            #expect(viewModel.posts(in: section).isEmpty)
            #expect(viewModel.count(in: section) == 0)
        }
        #expect(viewModel.receivedLikeCount == 0)
    }

    @Test
    func profileShowsCurrentUserNameAndReceivedLikes() {
        let viewModel = viewModel([
            post(title: "自分1", likes: 3),
            post(title: "自分2", likes: 4),
            post(title: "他人", author: "他人", likes: 100),
            post(title: "下書き", likes: 50, isDraft: true)
        ])
        #expect(viewModel.userName == me)
        #expect(viewModel.receivedLikeCount == 7)
    }

    @Test
    func initialMockDataUsesFixedNickname() {
        let viewModel = MyPageViewModel(repository: MockDataRepository(posts: MockData.posts(now: now)))
        #expect(viewModel.userName == "ぶっちゃけトラベラー")
        #expect(!viewModel.posts(in: .drafts).isEmpty)
    }

    @Test
    func starringAddsToSavedAndUnstarringRemoves() throws {
        let target = post(title: "対象", author: "他人")
        let repository = MockDataRepository(posts: [target], currentUserName: me)
        let viewModel = MyPageViewModel(repository: repository, section: .saved)
        #expect(viewModel.posts.isEmpty)

        viewModel.toggleStar(target)
        #expect(viewModel.posts.map(\.title) == ["対象"])
        #expect(try #require(repository.post(id: target.id)).starCount == 1)

        viewModel.toggleStar(target)
        #expect(viewModel.posts.isEmpty)
    }

    @Test
    func toggleLikeGoesThroughRepository() throws {
        let target = post(title: "対象", likes: 2)
        let repository = MockDataRepository(posts: [target], currentUserName: me)
        let viewModel = MyPageViewModel(repository: repository)

        viewModel.toggleLike(target)

        let updated = try #require(repository.post(id: target.id))
        #expect(updated.isLiked && updated.likeCount == 3)
        #expect(viewModel.posts.first?.isLiked == true)
        #expect(viewModel.receivedLikeCount == 3)
    }

    @Test
    func deletedPostsDisappearFromEverySection() {
        let published = post(title: "公開", isStarred: true)
        let draft = post(title: "下書き", isDraft: true)
        let repository = MockDataRepository(posts: [published, draft], currentUserName: me)
        let viewModel = MyPageViewModel(repository: repository)

        repository.delete(postID: published.id)
        repository.delete(postID: draft.id)

        #expect(viewModel.posts(in: .myPosts).isEmpty)
        #expect(viewModel.posts(in: .saved).isEmpty)
        #expect(viewModel.posts(in: .drafts).isEmpty)
    }

    @Test
    func deleteDraftRemovesItImmediately() {
        let older = post(title: "古い下書き", daysAgo: 2, isDraft: true)
        let newer = post(title: "新しい下書き", daysAgo: 1, isDraft: true)
        let repository = MockDataRepository(posts: [older, newer], currentUserName: me)
        let viewModel = MyPageViewModel(repository: repository, section: .drafts)

        viewModel.deleteDraft(newer)

        #expect(viewModel.posts.map(\.title) == ["古い下書き"])
        #expect(repository.post(id: newer.id) == nil)
    }

    @Test
    func deleteDraftKeepsPublishedAndOthersPosts() {
        let published = post(title: "公開")
        let othersDraft = post(title: "他人の下書き", author: "他人", isDraft: true)
        let repository = MockDataRepository(posts: [published, othersDraft], currentUserName: me)
        let viewModel = MyPageViewModel(repository: repository, section: .drafts)

        viewModel.deleteDraft(published)
        viewModel.deleteDraft(othersDraft)

        #expect(repository.posts.count == 2)
        #expect(viewModel.posts(in: .myPosts).map(\.title) == ["公開"])
    }

    @Test
    func publishingDraftMovesItFromDraftsToMyPosts() throws {
        let draft = post(title: "下書き", isDraft: true)
        let repository = MockDataRepository(posts: [draft], currentUserName: me)
        let viewModel = MyPageViewModel(repository: repository, section: .drafts)

        try repository.publish(draft, isNew: false)

        #expect(viewModel.posts.isEmpty)
        #expect(viewModel.posts(in: .myPosts).map(\.title) == ["下書き"])
    }

    @Test
    func postTurnedIntoDraftLeavesMyPostsAndSaved() throws {
        let published = post(title: "公開", isStarred: true)
        let repository = MockDataRepository(posts: [published], currentUserName: me)
        let viewModel = MyPageViewModel(repository: repository)

        repository.delete(postID: published.id)
        try repository.saveDraft(published, isNew: true)

        #expect(viewModel.posts(in: .myPosts).isEmpty)
        #expect(viewModel.posts(in: .saved).isEmpty)
        #expect(viewModel.posts(in: .drafts).map(\.title) == ["公開"])
    }

    @Test
    func draftTitleIsNilWhenBlank() {
        #expect(MyPageViewModel.draftTitle(of: post(title: "", isDraft: true)) == nil)
        #expect(MyPageViewModel.draftTitle(of: post(title: " 　\n", isDraft: true)) == nil)
        #expect(MyPageViewModel.draftTitle(of: post(title: " 東京の喫茶店 ", isDraft: true)) == "東京の喫茶店")
    }
}
