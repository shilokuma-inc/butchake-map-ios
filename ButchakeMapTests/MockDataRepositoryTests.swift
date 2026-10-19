//
//  MockDataRepositoryTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import Foundation
import Testing

@MainActor
struct MockDataRepositoryTests {
    private func makePost(
        title: String = "テスト",
        authorName: String = "他のだれか",
        createdAt: Date = Date(timeIntervalSince1970: 0),
        likeCount: Int = 0,
        starCount: Int = 0,
        isDraft: Bool = false
    ) -> Post {
        var post = Post.newDraft(authorName: authorName)
        post.title = title
        post.createdAt = createdAt
        post.likeCount = likeCount
        post.starCount = starCount
        post.isDraft = isDraft
        return post
    }

    // MARK: - 初期データ

    @Test
    func initialMockDataHasRequestedPosts() {
        let repository = MockDataRepository()
        let titles = repository.publishedPosts.map(\.title)
        #expect(titles.contains("金沢市民が本気で教える三大回転寿司"))
        #expect(titles.contains("愛あるツッコミ！全国三大がっかり名所の真実"))
        #expect(titles.contains("札幌市民が夜中に通う三大シメパフェ"))
        #expect(repository.publishedPosts.count >= 3)
    }

    @Test
    func everyMockPostHasThreeOrderedSpots() {
        for post in MockData.posts() {
            #expect(post.spots.count == Post.spotCount, "\(post.title)")
            #expect(post.spots.map(\.order) == [1, 2, 3], "\(post.title)")
        }
    }

    @Test
    func publishedMockSpotsHaveCoordinates() {
        for post in MockData.posts() where !post.isDraft {
            #expect(post.spots.allSatisfy { $0.coordinate != nil }, "\(post.title)")
        }
    }

    @Test
    func rawValuesAreStableIdentifiers() {
        #expect(AuthorType.allCases.map(\.rawValue) == ["local", "repeater", "traveler"])
        #expect(Category.allCases.map(\.rawValue) == ["gourmet", "scenery", "disappointment", "hiddenGem", "other"])
    }

    // MARK: - 読み出し

    @Test
    func publishedPostsExcludeDraftsAndAreNewestFirst() {
        let old = makePost(title: "古い", createdAt: Date(timeIntervalSince1970: 100))
        let new = makePost(title: "新しい", createdAt: Date(timeIntervalSince1970: 200))
        let draft = makePost(title: "下書き", isDraft: true)
        let repository = MockDataRepository(posts: [old, draft, new])
        #expect(repository.publishedPosts.map(\.title) == ["新しい", "古い"])
    }

    @Test
    func draftsAndMyPostsAreOnlyMine() {
        let mine = makePost(title: "自分の公開", authorName: "自分")
        let myDraft = makePost(title: "自分の下書き", authorName: "自分", isDraft: true)
        let othersDraft = makePost(title: "他人の下書き", isDraft: true)
        let others = makePost(title: "他人の公開")
        let repository = MockDataRepository(posts: [mine, myDraft, othersDraft, others], currentUserName: "自分")
        #expect(repository.myPosts.map(\.title) == ["自分の公開"])
        #expect(repository.drafts.map(\.title) == ["自分の下書き"])
    }

    // MARK: - いいね・スター

    @Test
    func toggleLikeUpdatesFlagAndCount() {
        let post = makePost(likeCount: 10)
        let repository = MockDataRepository(posts: [post])
        repository.toggleLike(postID: post.id)
        #expect(repository.post(id: post.id)?.isLiked == true)
        #expect(repository.post(id: post.id)?.likeCount == 11)
        repository.toggleLike(postID: post.id)
        #expect(repository.post(id: post.id)?.isLiked == false)
        #expect(repository.post(id: post.id)?.likeCount == 10)
    }

    @Test
    func toggleStarUpdatesFlagCountAndStarredPosts() {
        let post = makePost(starCount: 5)
        let repository = MockDataRepository(posts: [post])
        repository.toggleStar(postID: post.id)
        #expect(repository.post(id: post.id)?.isStarred == true)
        #expect(repository.post(id: post.id)?.starCount == 6)
        #expect(repository.starredPosts.map(\.id) == [post.id])
        repository.toggleStar(postID: post.id)
        #expect(repository.post(id: post.id)?.starCount == 5)
        #expect(repository.starredPosts.isEmpty)
    }

    @Test
    func toggleUnknownPostDoesNothing() {
        let post = makePost(likeCount: 1)
        let repository = MockDataRepository(posts: [post])
        repository.toggleLike(postID: UUID())
        repository.toggleStar(postID: UUID())
        #expect(repository.posts == [post])
    }

    // MARK: - 作成・編集・削除

    @Test
    func saveDraftAddsThenReplaces() throws {
        let repository = MockDataRepository(posts: [], currentUserName: "自分")
        var draft = Post.newDraft(authorName: "自分")
        draft.title = "一回目"
        try repository.saveDraft(draft, isNew: true)
        draft.title = "二回目"
        try repository.saveDraft(draft, isNew: false)
        #expect(repository.posts.count == 1)
        #expect(repository.drafts.map(\.title) == ["二回目"])
        #expect(repository.publishedPosts.isEmpty)
    }

    @Test
    func publishDraftMovesItToPublishedWithNewDate() throws {
        let draft = makePost(authorName: "自分", createdAt: Date(timeIntervalSince1970: 0), isDraft: true)
        let repository = MockDataRepository(posts: [draft], currentUserName: "自分")
        try repository.publish(draft, isNew: false)
        let published = try #require(repository.post(id: draft.id))
        #expect(!published.isDraft)
        #expect(published.createdAt > Date(timeIntervalSince1970: 0))
        #expect(repository.drafts.isEmpty)
        #expect(repository.myPosts.map(\.id) == [draft.id])
    }

    @Test
    func publishEditOfPublishedPostKeepsCreatedAt() throws {
        let createdAt = Date(timeIntervalSince1970: 1_000)
        var post = makePost(title: "前", authorName: "自分", createdAt: createdAt)
        let repository = MockDataRepository(posts: [post], currentUserName: "自分")
        post.title = "後"
        try repository.publish(post, isNew: false)
        #expect(repository.posts.count == 1)
        #expect(repository.post(id: post.id)?.title == "後")
        #expect(repository.post(id: post.id)?.createdAt == createdAt)
    }

    @Test
    func publishNewPostAddsItWithNewDate() throws {
        let repository = MockDataRepository(posts: [], currentUserName: "自分")
        let post = makePost(authorName: "自分", createdAt: Date(timeIntervalSince1970: 0), isDraft: true)
        try repository.publish(post, isNew: true)
        let published = try #require(repository.post(id: post.id))
        #expect(!published.isDraft)
        #expect(published.createdAt > Date(timeIntervalSince1970: 0))
        #expect(repository.myPosts.map(\.id) == [post.id])
    }

    @Test
    func publishEditKeepsStoredCreatedAtEvenIfPassedDateDiffers() throws {
        let createdAt = Date(timeIntervalSince1970: 1_000)
        var post = makePost(authorName: "自分", createdAt: createdAt)
        let repository = MockDataRepository(posts: [post], currentUserName: "自分")
        post.createdAt = Date(timeIntervalSince1970: 5_000)
        try repository.publish(post, isNew: false)
        #expect(repository.post(id: post.id)?.createdAt == createdAt)
    }

    @Test
    func saveDraftOfPublishedPostIsRejectedAndKeepsIt() {
        let createdAt = Date(timeIntervalSince1970: 1_000)
        var post = makePost(title: "公開済み", authorName: "自分", createdAt: createdAt)
        let repository = MockDataRepository(posts: [post], currentUserName: "自分")
        post.title = "書き換え"
        #expect(throws: PostSaveError.alreadyPublished) {
            try repository.saveDraft(post, isNew: false)
        }
        let stored = repository.post(id: post.id)
        #expect(stored?.isDraft == false)
        #expect(stored?.title == "公開済み")
        #expect(stored?.createdAt == createdAt)
        #expect(repository.drafts.isEmpty)
    }

    @Test
    func savingDeletedPostDoesNotRestoreIt() {
        let draft = makePost(authorName: "自分", isDraft: true)
        let published = makePost(authorName: "自分")
        let repository = MockDataRepository(posts: [draft, published], currentUserName: "自分")
        repository.delete(postID: draft.id)
        repository.delete(postID: published.id)
        #expect(throws: PostSaveError.notFound) {
            try repository.saveDraft(draft, isNew: false)
        }
        #expect(throws: PostSaveError.notFound) {
            try repository.publish(draft, isNew: false)
        }
        #expect(throws: PostSaveError.notFound) {
            try repository.publish(published, isNew: false)
        }
        #expect(repository.posts.isEmpty)
    }

    @Test
    func addingNewPostWithExistingIDIsRejected() {
        let post = makePost(title: "元", authorName: "自分", isDraft: true)
        let repository = MockDataRepository(posts: [post], currentUserName: "自分")
        var duplicate = post
        duplicate.title = "重複"
        #expect(throws: PostSaveError.alreadyExists) {
            try repository.saveDraft(duplicate, isNew: true)
        }
        #expect(throws: PostSaveError.alreadyExists) {
            try repository.publish(duplicate, isNew: true)
        }
        #expect(repository.posts == [post])
    }

    @Test
    func deleteRemovesPostEverywhere() {
        let post = makePost(authorName: "自分")
        let other = makePost(title: "残る")
        let repository = MockDataRepository(posts: [post, other], currentUserName: "自分")
        repository.toggleStar(postID: post.id)
        repository.delete(postID: post.id)
        #expect(repository.post(id: post.id) == nil)
        #expect(repository.publishedPosts.map(\.title) == ["残る"])
        #expect(repository.starredPosts.isEmpty)
    }

    @Test
    func updatingOthersPostIsRejectedAndKeepsIt() {
        let othersDraft = makePost(title: "他人の下書き", isDraft: true)
        let othersPost = makePost(title: "他人の公開")
        let repository = MockDataRepository(posts: [othersDraft, othersPost], currentUserName: "自分")
        // 渡す投稿の投稿者を自分に書き換えても、保存済みの投稿者で判定する
        var editedDraft = othersDraft
        editedDraft.title = "書き換え"
        editedDraft.authorName = "自分"
        var editedPost = othersPost
        editedPost.title = "書き換え"

        #expect(throws: PostSaveError.notMine) {
            try repository.saveDraft(editedDraft, isNew: false)
        }
        #expect(throws: PostSaveError.notMine) {
            try repository.publish(editedDraft, isNew: false)
        }
        #expect(throws: PostSaveError.notMine) {
            try repository.publish(editedPost, isNew: false)
        }
        #expect(repository.posts == [othersDraft, othersPost])
    }

    @Test
    func deleteRemovesOnlyMyPosts() {
        let mine = makePost(authorName: "自分")
        let myDraft = makePost(authorName: "自分", isDraft: true)
        let others = makePost(title: "他人の公開")
        let repository = MockDataRepository(posts: [mine, myDraft, others], currentUserName: "自分")

        #expect(!repository.delete(postID: others.id))
        #expect(!repository.delete(postID: UUID()))
        #expect(repository.delete(postID: mine.id))
        #expect(repository.delete(postID: myDraft.id))
        #expect(!repository.delete(postID: mine.id))
        #expect(repository.posts == [others])
    }

    @Test
    func updatingKeepsStoredAuthorName() throws {
        let draft = makePost(authorName: "自分", isDraft: true)
        let repository = MockDataRepository(posts: [draft], currentUserName: "自分")
        var edited = draft
        edited.authorName = "書き換えた名前"
        edited.title = "編集後"

        try repository.saveDraft(edited, isNew: false)
        #expect(try #require(repository.post(id: draft.id)).authorName == "自分")
        #expect(repository.drafts.map(\.title) == ["編集後"])

        try repository.publish(edited, isNew: false)
        let published = try #require(repository.post(id: draft.id))
        #expect(published.authorName == "自分")
        #expect(repository.myPosts.map(\.id) == [draft.id])
    }

    // MARK: - モデル

    @Test
    func newDraftHasThreeEmptySpots() {
        let draft = Post.newDraft(authorName: "自分")
        #expect(draft.isDraft)
        #expect(draft.spots.map(\.order) == [1, 2, 3])
        #expect(draft.spots.allSatisfy { $0.name.isEmpty && $0.coordinate == nil })
    }

    @Test
    func areaJoinsPrefectureAndCity() {
        var post = makePost()
        post.prefecture = "石川県"
        post.city = "金沢市"
        #expect(post.area == "石川県 金沢市")
        post.city = ""
        #expect(post.area == "石川県")
    }
}
