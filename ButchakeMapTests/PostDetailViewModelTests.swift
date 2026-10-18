//
//  PostDetailViewModelTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import Foundation
import Testing

struct PostDetailViewModelTests {
    private func post(authorName: String = "テスト", spotOrders: [Int] = [1, 2, 3], isDraft: Bool = false) -> Post {
        Post(
            authorName: authorName,
            authorType: .local,
            title: "テストの三大",
            prefecture: "東京都",
            city: "千代田区",
            category: .gourmet,
            spots: spotOrders.map { Spot(order: $0, name: "スポット\($0)", address: "", recommendation: "") },
            likeCount: 10,
            starCount: 2,
            isDraft: isDraft
        )
    }

    @Test
    func showsPostFromRepositoryWithSpotsInOrder() throws {
        let target = post(spotOrders: [3, 1, 2])
        let viewModel = PostDetailViewModel(repository: MockDataRepository(posts: [target]), postID: target.id)

        #expect(try #require(viewModel.post).id == target.id)
        #expect(viewModel.spots.map(\.order) == [1, 2, 3])
    }

    @Test
    func toggleLikeAndStarUpdateRepository() throws {
        let target = post()
        let repository = MockDataRepository(posts: [target])
        let viewModel = PostDetailViewModel(repository: repository, postID: target.id)

        viewModel.toggleLike()
        viewModel.toggleStar()

        let updated = try #require(repository.post(id: target.id))
        #expect(updated.isLiked && updated.likeCount == 11)
        #expect(updated.isStarred && updated.starCount == 3)
        #expect(viewModel.post == updated)
    }

    @Test
    func reflectsChangesMadeElsewhere() {
        let target = post()
        let repository = MockDataRepository(posts: [target])
        let viewModel = PostDetailViewModel(repository: repository, postID: target.id)

        repository.toggleStar(postID: target.id)

        #expect(viewModel.post?.isStarred == true)
    }

    @Test
    func deletedPostBecomesNil() {
        let target = post(authorName: MockData.currentUserName)
        let repository = MockDataRepository(posts: [target])
        let viewModel = PostDetailViewModel(repository: repository, postID: target.id)

        repository.delete(postID: target.id)

        #expect(viewModel.post == nil)
        #expect(viewModel.spots.isEmpty)
        #expect(!viewModel.isMine)
    }

    @Test
    func isMineFollowsCurrentUser() {
        let mine = post(authorName: MockData.currentUserName)
        let others = post()
        let repository = MockDataRepository(posts: [mine, others])

        #expect(PostDetailViewModel(repository: repository, postID: mine.id).isMine)
        #expect(!PostDetailViewModel(repository: repository, postID: others.id).isMine)
    }

    @Test
    func draftIsTreatedAsNotFoundAndCannotBeLikedOrStarred() throws {
        let draft = post(authorName: MockData.currentUserName, isDraft: true)
        let repository = MockDataRepository(posts: [draft])
        let viewModel = PostDetailViewModel(repository: repository, postID: draft.id)

        #expect(viewModel.post == nil)
        #expect(viewModel.spots.isEmpty)
        #expect(!viewModel.isMine)

        viewModel.toggleLike()
        viewModel.toggleStar()

        let stored = try #require(repository.post(id: draft.id))
        #expect(!stored.isLiked && stored.likeCount == 10)
        #expect(!stored.isStarred && stored.starCount == 2)
    }

    @Test
    func postDisappearsWhenTurnedIntoDraft() throws {
        let target = post(authorName: MockData.currentUserName)
        let repository = MockDataRepository(posts: [target])
        let viewModel = PostDetailViewModel(repository: repository, postID: target.id)
        #expect(viewModel.post != nil)

        repository.delete(postID: target.id)
        try repository.saveDraft(target, isNew: true)

        #expect(viewModel.post == nil)
    }

    // MARK: - 編集・削除

    @Test
    func onlyMyPostCanBeEditedOrDeleted() {
        let mine = post(authorName: MockData.currentUserName)
        let others = post()
        let repository = MockDataRepository(posts: [mine, others])
        let myViewModel = PostDetailViewModel(repository: repository, postID: mine.id)
        let othersViewModel = PostDetailViewModel(repository: repository, postID: others.id)

        #expect(myViewModel.canEditOrDelete)
        #expect(myViewModel.editablePost == mine)
        #expect(!othersViewModel.canEditOrDelete)
        #expect(othersViewModel.editablePost == nil)
    }

    @Test
    func deletedOrDraftPostCannotBeEditedOrDeleted() {
        let draft = post(authorName: MockData.currentUserName, isDraft: true)
        let repository = MockDataRepository(posts: [draft])
        let missing = PostDetailViewModel(repository: repository, postID: UUID())
        let draftViewModel = PostDetailViewModel(repository: repository, postID: draft.id)

        #expect(!missing.canEditOrDelete)
        #expect(missing.editablePost == nil)
        #expect(!missing.delete())
        #expect(!draftViewModel.canEditOrDelete)
        #expect(!draftViewModel.delete())
        #expect(repository.posts == [draft])
    }

    @Test
    func deletingMyPostRemovesItAndShowsNotFound() {
        let mine = post(authorName: MockData.currentUserName)
        let others = post()
        let repository = MockDataRepository(posts: [mine, others])
        let viewModel = PostDetailViewModel(repository: repository, postID: mine.id)

        #expect(viewModel.delete())

        #expect(repository.post(id: mine.id) == nil)
        #expect(repository.posts.map(\.id) == [others.id])
        #expect(viewModel.post == nil)
        #expect(!viewModel.canEditOrDelete)
    }

    @Test
    func othersPostCannotBeDeleted() {
        let others = post()
        let repository = MockDataRepository(posts: [others])

        #expect(!PostDetailViewModel(repository: repository, postID: others.id).delete())

        #expect(repository.posts == [others])
    }

    @Test
    func deletingMyPostRemovesItFromEveryScreen() throws {
        var mine = post(authorName: MockData.currentUserName)
        for index in mine.spots.indices {
            mine.spots[index].latitude = 35.68
            mine.spots[index].longitude = 139.76
        }
        let repository = MockDataRepository(posts: [mine])
        repository.toggleStar(postID: mine.id)
        let home = HomeViewModel(repository: repository)
        let search = SearchViewModel(repository: repository)
        let map = PostMapViewModel(repository: repository)
        let myPage = MyPageViewModel(repository: repository)
        #expect(home.feedPosts.map(\.id) == [mine.id])
        #expect(search.results(for: SearchFilter()).map(\.id) == [mine.id])
        let pinID = try #require(map.pins.first).id
        #expect(myPage.posts(in: .myPosts).map(\.id) == [mine.id])
        #expect(myPage.posts(in: .saved).map(\.id) == [mine.id])

        PostDetailViewModel(repository: repository, postID: mine.id).delete()

        #expect(home.feedPosts.isEmpty)
        #expect(home.trendingPosts.isEmpty)
        #expect(search.results(for: SearchFilter()).isEmpty)
        #expect(map.pins.isEmpty)
        #expect(map.post(for: pinID) == nil)
        #expect(myPage.posts(in: .myPosts).isEmpty)
        #expect(myPage.posts(in: .saved).isEmpty)
    }

    @Test
    func publishingEditKeepsLikesAndStarsAndClosesEditor() throws {
        var mine = post(authorName: MockData.currentUserName)
        for index in mine.spots.indices {
            mine.spots[index].recommendation = "おすすめ"
        }
        let repository = MockDataRepository(posts: [mine])
        repository.toggleLike(postID: mine.id)
        repository.toggleStar(postID: mine.id)
        let detail = PostDetailViewModel(repository: repository, postID: mine.id)
        let editable = try #require(detail.editablePost)
        let form = PostCreateViewModel(post: editable, repository: repository)
        #expect(!form.showsSaveDraftButton)

        form.post.title = "編集後の三大"
        form.publish()

        let outcome = try #require(form.outcome)
        #expect(outcome == .published)
        #expect(PostDetailViewModel.closesEditor(after: outcome))
        let edited = try #require(detail.post)
        #expect(edited.title == "編集後の三大")
        #expect(edited.isLiked && edited.likeCount == 11)
        #expect(edited.isStarred && edited.starCount == 3)
        #expect(edited.createdAt == mine.createdAt)
    }

    @Test
    func editorClosesAfterPublishingOrWhenPostCannotBeSaved() {
        #expect(PostDetailViewModel.closesEditor(after: .published))
        #expect(PostDetailViewModel.closesEditor(after: .failed(.notFound)))
        #expect(PostDetailViewModel.closesEditor(after: .failed(.notMine)))
        #expect(!PostDetailViewModel.closesEditor(after: .failed(.alreadyPublished)))
    }
}
