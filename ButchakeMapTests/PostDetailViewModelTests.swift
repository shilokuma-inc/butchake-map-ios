//
//  PostDetailViewModelTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import Foundation
import Testing

struct PostDetailViewModelTests {
    private func post(authorName: String = "テスト", spotOrders: [Int] = [1, 2, 3]) -> Post {
        Post(
            authorName: authorName,
            authorType: .local,
            title: "テストの三大",
            prefecture: "東京都",
            city: "千代田区",
            category: .gourmet,
            spots: spotOrders.map { Spot(order: $0, name: "スポット\($0)", address: "", recommendation: "") },
            likeCount: 10,
            starCount: 2
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
        let target = post()
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
}
