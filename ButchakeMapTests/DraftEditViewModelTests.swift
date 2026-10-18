//
//  DraftEditViewModelTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import Foundation
import Testing

struct DraftEditViewModelTests {
    private let me = "自分"

    private func post(author: String? = nil, isDraft: Bool = true) -> Post {
        var post = Post.newDraft(authorName: author ?? me)
        post.title = "下書きの三大"
        post.isDraft = isDraft
        return post
    }

    private func repository(_ posts: [Post]) -> MockDataRepository {
        MockDataRepository(posts: posts, currentUserName: me)
    }

    @Test
    func opensMyDraft() {
        let draft = post()
        let viewModel = DraftEditViewModel(postID: draft.id, repository: repository([draft]))
        #expect(viewModel.draft == draft)
    }

    @Test
    func doesNotOpenDeletedPublishedOrOthersPosts() {
        let published = post(isDraft: false)
        let othersDraft = post(author: "他人")
        let repository = repository([published, othersDraft])

        #expect(DraftEditViewModel(postID: UUID(), repository: repository).draft == nil)
        #expect(DraftEditViewModel(postID: published.id, repository: repository).draft == nil)
        #expect(DraftEditViewModel(postID: othersDraft.id, repository: repository).draft == nil)
    }

    @Test
    func keepsDraftAsOpenedEvenAfterPublishing() throws {
        let draft = post()
        let repository = repository([draft])
        let viewModel = DraftEditViewModel(postID: draft.id, repository: repository)

        try repository.publish(draft, isNew: false)

        #expect(viewModel.draft == draft)
    }

    @Test
    func closesAfterPublishingOrWhenDeletedButStaysAfterSavingDraft() {
        #expect(DraftEditViewModel.closesForm(after: .published))
        #expect(DraftEditViewModel.closesForm(after: .failed(.notFound)))
        #expect(!DraftEditViewModel.closesForm(after: .savedDraft))
        #expect(!DraftEditViewModel.closesForm(after: .failed(.alreadyPublished)))
        #expect(!DraftEditViewModel.closesForm(after: .failed(.alreadyExists)))
    }

    @Test
    func publishingOpenedDraftMovesItToMyPostsAndClosesForm() throws {
        var draft = post()
        draft.prefecture = "東京都"
        draft.city = "台東区"
        for index in draft.spots.indices {
            draft.spots[index].name = "スポット\(index + 1)"
            draft.spots[index].recommendation = "おすすめ"
        }
        let repository = repository([draft])
        let opened = try #require(DraftEditViewModel(postID: draft.id, repository: repository).draft)
        let form = PostCreateViewModel(post: opened, repository: repository)

        form.publish()

        let outcome = try #require(form.outcome)
        #expect(outcome == .published)
        #expect(DraftEditViewModel.closesForm(after: outcome))
        #expect(repository.drafts.isEmpty)
        #expect(repository.myPosts.map(\.id) == [draft.id])
    }

    @Test
    func savingDraftDeletedWhileEditingFailsAndClosesForm() throws {
        let draft = post()
        let repository = repository([draft])
        let opened = try #require(DraftEditViewModel(postID: draft.id, repository: repository).draft)
        let form = PostCreateViewModel(post: opened, repository: repository)

        repository.delete(postID: draft.id)
        form.saveDraft()

        let outcome = try #require(form.outcome)
        #expect(outcome == .failed(.notFound))
        #expect(DraftEditViewModel.closesForm(after: outcome))
        #expect(repository.posts.isEmpty)
    }
}
