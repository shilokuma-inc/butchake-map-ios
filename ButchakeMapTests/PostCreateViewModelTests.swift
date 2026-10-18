//
//  PostCreateViewModelTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import Foundation
import Testing

@MainActor
struct PostCreateViewModelTests {
    private let me = "自分"

    private func makeRepository(posts: [Post] = []) -> MockDataRepository {
        MockDataRepository(posts: posts, currentUserName: me)
    }

    /// 公開に必要な項目をすべて埋めた投稿
    private func filledPost(isDraft: Bool = true, createdAt: Date = Date(timeIntervalSince1970: 0)) -> Post {
        var post = Post.newDraft(authorName: me)
        post.title = "テストの三大"
        post.prefecture = Prefecture.ishikawa.rawValue
        post.city = "金沢市"
        post.category = .scenery
        post.authorType = .local
        for index in post.spots.indices {
            post.spots[index].name = "スポット\(index + 1)"
            post.spots[index].recommendation = "おすすめ\(index + 1)"
        }
        post.createdAt = createdAt
        post.isDraft = isDraft
        return post
    }

    // MARK: - 初期状態

    @Test
    func newFormStartsWithMyEmptyDraft() {
        let viewModel = PostCreateViewModel(post: nil, repository: makeRepository())
        #expect(viewModel.isNew)
        #expect(viewModel.post.authorName == me)
        #expect(viewModel.post.isDraft)
        #expect(viewModel.post.spots.map(\.order) == [1, 2, 3])
        #expect(viewModel.showsSaveDraftButton)
        #expect(!viewModel.canSaveDraft)
        #expect(!viewModel.canPublish)
    }

    @Test
    func existingPostIsEditedAsIs() {
        let draft = filledPost()
        let viewModel = PostCreateViewModel(post: draft, repository: makeRepository(posts: [draft]))
        #expect(!viewModel.isNew)
        #expect(viewModel.post == draft)
        #expect(viewModel.canPublish)
    }

    // MARK: - 入力チェック

    @Test
    func requiredErrorsAppearOnlyAfterPublishAttempt() {
        let repository = makeRepository()
        let viewModel = PostCreateViewModel(post: nil, repository: repository)
        #expect(viewModel.error(for: .title) == nil)

        viewModel.publish()

        #expect(viewModel.showsRequiredErrors)
        #expect(viewModel.error(for: .title) == .required)
        #expect(viewModel.error(for: .prefecture) == .unselected)
        #expect(viewModel.error(for: .city) == .required)
        #expect(viewModel.error(for: .spotName(order: 2)) == .required)
        #expect(viewModel.error(for: .spotRecommendation(order: 3)) == .required)
        #expect(viewModel.error(for: .spotAddress(order: 1)) == nil)
        #expect(repository.posts.isEmpty)
        #expect(viewModel.outcome == nil)
    }

    @Test
    func whitespaceOnlyCountsAsEmpty() {
        var post = filledPost()
        post.title = "  \n "
        #expect(PostCreateViewModel.validate(post, requiresAll: true) == [.title: .required])
    }

    @Test
    func unknownPrefectureIsRejected() {
        var post = filledPost()
        post.prefecture = "架空県"
        #expect(PostCreateViewModel.validate(post, requiresAll: true) == [.prefecture: .unselected])
    }

    @Test
    func lengthLimitsApplyEvenToDrafts() {
        var post = filledPost()
        post.title = String(repeating: "あ", count: PostCreateViewModel.Limit.title + 1)
        post.spots[0].address = String(repeating: "あ", count: PostCreateViewModel.Limit.spotAddress + 1)
        let errors = PostCreateViewModel.validate(post, requiresAll: false)
        #expect(errors[.title] == .tooLong(limit: PostCreateViewModel.Limit.title))
        #expect(errors[.spotAddress(order: 1)] == .tooLong(limit: PostCreateViewModel.Limit.spotAddress))

        let viewModel = PostCreateViewModel(post: nil, repository: makeRepository())
        viewModel.post = post
        #expect(viewModel.error(for: .title) == .tooLong(limit: PostCreateViewModel.Limit.title))
        #expect(!viewModel.canSaveDraft)
        #expect(!viewModel.canPublish)
    }

    @Test
    func textAtLimitIsAccepted() {
        var post = filledPost()
        post.title = String(repeating: "あ", count: PostCreateViewModel.Limit.title)
        post.spots[2].recommendation = String(repeating: "あ", count: PostCreateViewModel.Limit.spotRecommendation)
        #expect(PostCreateViewModel.validate(post, requiresAll: true).isEmpty)
    }

    // MARK: - 下書き保存

    @Test
    func saveDraftWorksWithPartialInputAndResetsForm() throws {
        let repository = makeRepository()
        let viewModel = PostCreateViewModel(post: nil, repository: repository)
        viewModel.post.spots[0].name = "  途中まで  "
        let savedID = viewModel.post.id
        #expect(viewModel.canSaveDraft)

        viewModel.saveDraft()

        let saved = try #require(repository.post(id: savedID))
        #expect(saved.isDraft)
        #expect(saved.title.isEmpty)
        #expect(saved.spots[0].name == "途中まで")
        #expect(repository.drafts.map(\.id) == [savedID])
        #expect(viewModel.outcome == .savedDraft)
        #expect(viewModel.isNew)
        #expect(viewModel.post.id != savedID)
        #expect(viewModel.post.spots[0].name.isEmpty)
    }

    @Test
    func emptyFormCannotBeSavedAsDraft() {
        let repository = makeRepository()
        let viewModel = PostCreateViewModel(post: nil, repository: repository)
        viewModel.post.category = .other
        viewModel.saveDraft()
        #expect(repository.posts.isEmpty)
        #expect(viewModel.outcome == nil)
    }

    @Test
    func editingDraftReplacesIt() throws {
        let draft = filledPost()
        let repository = makeRepository(posts: [draft])
        let viewModel = PostCreateViewModel(post: draft, repository: repository)
        viewModel.post.title = "書き直し"

        viewModel.saveDraft()

        #expect(repository.posts.count == 1)
        #expect(try #require(repository.post(id: draft.id)).title == "書き直し")
    }

    @Test
    func publishedPostHidesSaveDraft() {
        let published = filledPost(isDraft: false)
        let repository = makeRepository(posts: [published])
        let viewModel = PostCreateViewModel(post: published, repository: repository)
        #expect(!viewModel.showsSaveDraftButton)
        #expect(!viewModel.canSaveDraft)

        viewModel.saveDraft()

        #expect(repository.post(id: published.id)?.isDraft == false)
        #expect(repository.drafts.isEmpty)
    }

    // MARK: - 公開

    @Test
    func publishNewPostShowsOnHomeAndResetsForm() throws {
        let repository = makeRepository()
        let viewModel = PostCreateViewModel(post: nil, repository: repository)
        let post = filledPost()
        viewModel.post = post

        viewModel.publish()

        let published = try #require(repository.post(id: post.id))
        #expect(!published.isDraft)
        #expect(published.createdAt > Date(timeIntervalSince1970: 0))
        #expect(HomeViewModel(repository: repository).feedPosts.map(\.id) == [post.id])
        #expect(repository.myPosts.map(\.id) == [post.id])
        #expect(viewModel.outcome == .published)
        #expect(viewModel.isNew)
        #expect(!viewModel.showsRequiredErrors)
        #expect(viewModel.post.title.isEmpty)
    }

    @Test
    func publishDraftMovesItOutOfDrafts() {
        let draft = filledPost()
        let repository = makeRepository(posts: [draft])
        let viewModel = PostCreateViewModel(post: draft, repository: repository)

        viewModel.publish()

        #expect(repository.drafts.isEmpty)
        #expect(repository.myPosts.map(\.id) == [draft.id])
    }

    @Test
    func publishEditOfPublishedPostKeepsCreatedAt() {
        let createdAt = Date(timeIntervalSince1970: 1_000)
        let published = filledPost(isDraft: false, createdAt: createdAt)
        let repository = makeRepository(posts: [published])
        let viewModel = PostCreateViewModel(post: published, repository: repository)
        viewModel.post.title = "直した"

        viewModel.publish()

        #expect(repository.post(id: published.id)?.title == "直した")
        #expect(repository.post(id: published.id)?.createdAt == createdAt)
    }

    @Test
    func postDeletedWhileEditingIsNotRestored() {
        let draft = filledPost()
        let repository = makeRepository(posts: [draft])
        let viewModel = PostCreateViewModel(post: draft, repository: repository)
        repository.delete(postID: draft.id)

        viewModel.publish()
        #expect(viewModel.outcome == .failed(.notFound))
        viewModel.saveDraft()

        #expect(repository.posts.isEmpty)
        #expect(viewModel.outcome == .failed(.notFound))
        #expect(viewModel.post.id == draft.id)
    }

    @Test
    func editingKeepsLikesAndStarsMadeElsewhere() throws {
        let published = filledPost(isDraft: false)
        let repository = makeRepository(posts: [published])
        let viewModel = PostCreateViewModel(post: published, repository: repository)
        repository.toggleLike(postID: published.id)
        repository.toggleStar(postID: published.id)
        viewModel.post.title = "直した"

        viewModel.publish()

        let saved = try #require(repository.post(id: published.id))
        #expect(saved.title == "直した")
        #expect(saved.isLiked && saved.likeCount == published.likeCount + 1)
        #expect(saved.isStarred && saved.starCount == published.starCount + 1)
    }

    @Test
    func editingKeepsFormAfterSaving() {
        let draft = filledPost()
        let repository = makeRepository(posts: [draft])
        let viewModel = PostCreateViewModel(post: draft, repository: repository)
        viewModel.post.title = "書き直し"

        viewModel.saveDraft()

        #expect(!viewModel.isNew)
        #expect(viewModel.post.id == draft.id)
        #expect(viewModel.post.title == "書き直し")

        viewModel.publish()

        #expect(viewModel.outcome == .published)
        #expect(viewModel.post.id == draft.id)
        #expect(!viewModel.post.isDraft)
        #expect(!viewModel.showsSaveDraftButton)
    }

    @Test
    func draftPublishedElsewhereCannotBeSavedAsDraft() {
        let draft = filledPost()
        let repository = makeRepository(posts: [draft])
        let viewModel = PostCreateViewModel(post: draft, repository: repository)
        try? repository.publish(draft, isNew: false)
        viewModel.post.title = "下書きのつもり"

        viewModel.saveDraft()

        #expect(viewModel.outcome == .failed(.alreadyPublished))
        #expect(repository.post(id: draft.id)?.isDraft == false)
        #expect(repository.post(id: draft.id)?.title == draft.title)
    }

    @Test
    func publishTrimsWhitespace() throws {
        let repository = makeRepository()
        let viewModel = PostCreateViewModel(post: nil, repository: repository)
        var post = filledPost()
        post.title = "  前後に空白  "
        post.spots[0].name = "\nスポット\n"
        viewModel.post = post

        viewModel.publish()

        let published = try #require(repository.post(id: post.id))
        #expect(published.title == "前後に空白")
        #expect(published.spots[0].name == "スポット")
    }

    // MARK: - 都道府県

    @Test
    func prefecturesCoverAllFortySevenAndMockData() {
        #expect(Prefecture.allCases.count == 47)
        #expect(Set(Prefecture.allCases.map(\.rawValue)).count == 47)
        #expect(Prefecture.allCases.first == .hokkaido)
        #expect(Prefecture.allCases.last == .okinawa)
        for post in MockData.posts() {
            #expect(Prefecture(rawValue: post.prefecture) != nil, "\(post.prefecture)")
        }
    }
}
