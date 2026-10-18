//
//  PostCreateLocationTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import CoreLocation
import Foundation
import Testing

@MainActor
struct PostCreateLocationTests {
    private let me = "自分"
    private let kanazawa = CLLocationCoordinate2D(latitude: 36.5717, longitude: 136.6565)

    private func makeViewModel(post: Post? = nil) -> (PostCreateViewModel, MockDataRepository) {
        let repository = MockDataRepository(posts: post.map { [$0] } ?? [], currentUserName: me)
        return (PostCreateViewModel(post: post, repository: repository), repository)
    }

    /// 公開に必要な項目をすべて埋めた（位置は選んでいない）投稿
    private func filledPost() -> Post {
        var post = Post.newDraft(authorName: me)
        post.title = "テストの三大"
        post.prefecture = Prefecture.ishikawa.rawValue
        post.city = "金沢市"
        for index in post.spots.indices {
            post.spots[index].name = "スポット\(index + 1)"
            post.spots[index].recommendation = "おすすめ\(index + 1)"
        }
        return post
    }

    // MARK: - 設定・解除

    @Test
    func setLocationUpdatesOnlyThatSpot() {
        let (viewModel, _) = makeViewModel()

        viewModel.setLocation(kanazawa, forSpot: 2)

        #expect(viewModel.post.spots.map(\.latitude) == [nil, 36.5717, nil])
        #expect(viewModel.post.spots.map(\.longitude) == [nil, 136.6565, nil])
    }

    @Test
    func setLocationRoundsToSixFractionDigits() throws {
        let (viewModel, _) = makeViewModel()

        viewModel.setLocation(CLLocationCoordinate2D(latitude: 36.123_456_789, longitude: 136.987_654_321), forSpot: 1)

        let coordinate = try #require(viewModel.post.spots[0].coordinate)
        #expect(coordinate.latitude == 36.123_457)
        #expect(coordinate.longitude == 136.987_654)
    }

    @Test
    func chooseAgainReplacesLocation() {
        let (viewModel, _) = makeViewModel()
        viewModel.setLocation(kanazawa, forSpot: 1)

        viewModel.setLocation(CLLocationCoordinate2D(latitude: 35.0, longitude: 135.0), forSpot: 1)

        #expect(viewModel.post.spots[0].latitude == 35.0)
        #expect(viewModel.post.spots[0].longitude == 135.0)
    }

    @Test
    func clearLocationRemovesBothValues() {
        var post = filledPost()
        post.spots[2].latitude = 36.5
        post.spots[2].longitude = nil
        post.spots[0].latitude = 36.5
        post.spots[0].longitude = 136.6
        let (viewModel, _) = makeViewModel(post: post)

        viewModel.clearLocation(forSpot: 1)
        viewModel.clearLocation(forSpot: 3)

        #expect(viewModel.post.spots.allSatisfy { $0.latitude == nil && $0.longitude == nil })
    }

    @Test
    func unknownSpotOrderIsIgnored() {
        let (viewModel, _) = makeViewModel()
        let before = viewModel.post

        viewModel.setLocation(kanazawa, forSpot: 4)
        viewModel.clearLocation(forSpot: 0)

        #expect(viewModel.post == before)
    }

    // MARK: - 初期表示の範囲

    @Test
    func pickerStartsAtSelectedLocation() {
        let (viewModel, _) = makeViewModel()
        viewModel.post.prefecture = Prefecture.hokkaido.rawValue
        viewModel.setLocation(kanazawa, forSpot: 1)

        let region = viewModel.locationPickerRegion(forSpot: 1)

        #expect(region.center.latitude == kanazawa.latitude && region.center.longitude == kanazawa.longitude)
        #expect(region.span.latitudeDelta == PostCreateViewModel.LocationSpan.selected)
    }

    @Test
    func pickerStartsAroundPrefectureWithoutLocation() throws {
        let (viewModel, _) = makeViewModel()
        viewModel.post.prefecture = Prefecture.ishikawa.rawValue
        viewModel.setLocation(kanazawa, forSpot: 1)

        let region = viewModel.locationPickerRegion(forSpot: 2)
        let capital = try #require(Prefecture.ishikawa.capitalCoordinate)

        #expect(region.center.latitude == capital.latitude && region.center.longitude == capital.longitude)
        #expect(region.span.latitudeDelta == PostCreateViewModel.LocationSpan.prefecture)
    }

    @Test
    func pickerStartsWithWholeJapanWithoutPrefecture() {
        let (viewModel, _) = makeViewModel()

        let region = viewModel.locationPickerRegion(forSpot: 1)

        #expect(region.center.latitude == PostMapViewModel.japanRegion.center.latitude)
        #expect(region.center.longitude == PostMapViewModel.japanRegion.center.longitude)
        #expect(region.span.latitudeDelta == PostMapViewModel.japanRegion.span.latitudeDelta)
    }

    @Test
    func everyPrefectureHasCapitalCoordinateInJapan() throws {
        for prefecture in Prefecture.allCases {
            let coordinate = try #require(prefecture.capitalCoordinate, "\(prefecture.rawValue)")
            #expect((24.0...46.0).contains(coordinate.latitude), "\(prefecture.rawValue)")
            #expect((122.0...146.0).contains(coordinate.longitude), "\(prefecture.rawValue)")
        }
    }

    // MARK: - 保存・公開

    @Test
    func publishDoesNotRequireLocation() {
        let (viewModel, repository) = makeViewModel()
        viewModel.post = filledPost()

        viewModel.publish()

        #expect(viewModel.outcome == .published)
        #expect(repository.publishedPosts.count == 1)
    }

    @Test
    func locationOnlyCanBeSavedAsDraftAndIsKept() throws {
        let (viewModel, repository) = makeViewModel()
        #expect(!viewModel.canSaveDraft)

        viewModel.setLocation(kanazawa, forSpot: 3)
        let draftID = viewModel.post.id
        viewModel.saveDraft()

        #expect(viewModel.outcome == .savedDraft)
        let saved = try #require(repository.post(id: draftID))
        #expect(saved.spots[2].latitude == 36.5717 && saved.spots[2].longitude == 136.6565)
    }

    @Test
    func publishedLocationIsKept() throws {
        let (viewModel, repository) = makeViewModel()
        viewModel.post = filledPost()
        viewModel.setLocation(kanazawa, forSpot: 1)
        let postID = viewModel.post.id

        viewModel.publish()

        let published = try #require(repository.post(id: postID))
        #expect(published.spots[0].latitude == 36.5717 && published.spots[0].longitude == 136.6565)
    }
}
