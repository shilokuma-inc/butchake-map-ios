//
//  PostCreatePhotoTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import Foundation
import Testing

@MainActor
struct PostCreatePhotoTests {
    private let me = "自分"
    private let photo = Data([0xFF, 0xD8, 0x01])
    private let anotherPhoto = Data([0xFF, 0xD8, 0x02])

    private func makeViewModel(post: Post? = nil) -> (PostCreateViewModel, MockDataRepository) {
        let repository = MockDataRepository(posts: post.map { [$0] } ?? [], currentUserName: me)
        return (PostCreateViewModel(post: post, repository: repository), repository)
    }

    /// 公開に必要な項目をすべて埋めた（写真は選んでいない）投稿
    private func filledPost(isDraft: Bool = true) -> Post {
        var post = Post.newDraft(authorName: me)
        post.title = "テストの三大"
        post.prefecture = Prefecture.ishikawa.rawValue
        post.city = "金沢市"
        for index in post.spots.indices {
            post.spots[index].name = "スポット\(index + 1)"
            post.spots[index].recommendation = "おすすめ\(index + 1)"
        }
        post.isDraft = isDraft
        return post
    }

    // MARK: - 設定・削除

    @Test
    func setPhotoUpdatesOnlyThatSpot() {
        let (viewModel, _) = makeViewModel()

        viewModel.setPhoto(photo, forSpot: 2)

        #expect(viewModel.post.spots.map(\.photoData) == [nil, photo, nil])
    }

    @Test
    func chooseAgainReplacesPhoto() {
        let (viewModel, _) = makeViewModel()
        viewModel.setPhoto(photo, forSpot: 1)

        viewModel.setPhoto(anotherPhoto, forSpot: 1)

        #expect(viewModel.post.spots[0].photoData == anotherPhoto)
    }

    @Test
    func removePhotoClearsOnlyThatSpot() {
        let (viewModel, _) = makeViewModel()
        viewModel.setPhoto(photo, forSpot: 1)
        viewModel.setPhoto(anotherPhoto, forSpot: 3)

        viewModel.removePhoto(forSpot: 1)

        #expect(viewModel.post.spots.map(\.photoData) == [nil, nil, anotherPhoto])
    }

    @Test
    func unknownSpotIsIgnored() {
        let (viewModel, _) = makeViewModel()
        let before = viewModel.post

        viewModel.setPhoto(photo, forSpot: 9)
        viewModel.removePhoto(forSpot: 9)

        #expect(viewModel.post == before)
    }

    @Test
    func photoIsKeptWhenEditingOtherFields() {
        let (viewModel, _) = makeViewModel()
        viewModel.setPhoto(photo, forSpot: 1)

        viewModel.post.spots[0].name = "もりもり寿し"

        #expect(viewModel.post.spots[0].photoData == photo)
        #expect(viewModel.post.spots[0].photoUrl == nil)
    }

    // MARK: - 保存・公開

    @Test
    func publishDoesNotRequirePhotos() {
        let (viewModel, repository) = makeViewModel()
        viewModel.post = filledPost()

        viewModel.publish()

        #expect(viewModel.outcome == .published)
        #expect(repository.publishedPosts.count == 1)
    }

    @Test
    func photoOnlyCanBeSavedAsDraftAndIsKept() throws {
        let (viewModel, repository) = makeViewModel()
        #expect(!viewModel.canSaveDraft)

        viewModel.setPhoto(photo, forSpot: 2)
        #expect(viewModel.canSaveDraft)
        let draftID = viewModel.post.id
        viewModel.saveDraft()

        #expect(viewModel.outcome == .savedDraft)
        let saved = try #require(repository.post(id: draftID))
        #expect(saved.spots[1].photoData == photo)
    }

    @Test
    func editedPhotoIsSavedAndStaysInForm() throws {
        var post = filledPost(isDraft: false)
        post.spots[0].photoData = photo
        let (viewModel, repository) = makeViewModel(post: post)

        viewModel.setPhoto(anotherPhoto, forSpot: 1)
        viewModel.removePhoto(forSpot: 1)
        viewModel.setPhoto(anotherPhoto, forSpot: 2)
        viewModel.publish()

        let published = try #require(repository.post(id: post.id))
        #expect(published.spots.map(\.photoData) == [nil, anotherPhoto, nil])
        #expect(viewModel.post.spots.map(\.photoData) == [nil, anotherPhoto, nil])
    }

    // MARK: - カードのサムネイル

    @Test
    func coverPhotoIsFirstSpotWithPhoto() {
        var post = filledPost()
        #expect(post.coverPhotoData == nil)

        post.spots[2].photoData = anotherPhoto
        #expect(post.coverPhotoData == anotherPhoto)

        post.spots[1].photoData = photo
        #expect(post.coverPhotoData == photo)
    }

    @Test
    func coverPhotoFollowsSpotOrderNotArrayOrder() {
        var post = filledPost()
        post.spots[0].photoData = anotherPhoto
        post.spots[2].photoData = photo
        post.spots.reverse()

        #expect(post.coverPhotoData == anotherPhoto)
    }
}
