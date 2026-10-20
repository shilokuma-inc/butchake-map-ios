//
//  PostMapViewModelTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import CoreLocation
import Foundation
import Testing

struct PostMapViewModelTests {
    private func spot(order: Int, latitude: Double? = 35.0, longitude: Double? = 135.0) -> Spot {
        Spot(
            order: order,
            name: "スポット\(order)",
            address: "",
            latitude: latitude.map { $0 + Double(order) * 0.01 },
            longitude: longitude.map { $0 + Double(order) * 0.01 },
            recommendation: ""
        )
    }

    private func post(
        title: String = "テストの三大",
        spots: [Spot]? = nil,
        createdAt: Date = Date(),
        isDraft: Bool = false
    ) -> Post {
        Post(
            authorName: "テスト",
            authorType: .local,
            title: title,
            prefecture: "東京都",
            city: "千代田区",
            category: .scenery,
            spots: spots ?? [spot(order: 1), spot(order: 2), spot(order: 3)],
            likeCount: 10,
            starCount: 2,
            createdAt: createdAt,
            isDraft: isDraft
        )
    }

    @Test
    func pinsArePerSpotInPostAndSpotOrder() {
        let older = post(title: "古い", createdAt: Date(timeIntervalSinceNow: -100))
        let newer = post(title: "新しい", spots: [spot(order: 3), spot(order: 1), spot(order: 2)])
        let viewModel = PostMapViewModel(repository: MockDataRepository(posts: [older, newer]))

        let pins = viewModel.pins

        #expect(pins.count == 6)
        #expect(pins.map(\.postTitle) == ["新しい", "新しい", "新しい", "古い", "古い", "古い"])
        #expect(pins.map(\.order) == [1, 2, 3, 1, 2, 3])
        #expect(Set(pins.map(\.id)).count == 6)
        #expect(pins.allSatisfy { $0.category == .scenery })
    }

    @Test
    func pinCarriesSpotNameAndCoordinate() throws {
        let target = post()
        let viewModel = PostMapViewModel(repository: MockDataRepository(posts: [target]))

        let pin = try #require(viewModel.pins.first)
        let source = try #require(target.spots.first)

        #expect(pin.id == MapPinID(postID: target.id, spotID: source.id))
        #expect(pin.spotName == source.name)
        #expect(pin.latitude == source.latitude && pin.longitude == source.longitude)
    }

    @Test
    func spotsWithoutCoordinateHaveNoPin() {
        let target = post(spots: [
            spot(order: 1),
            spot(order: 2, latitude: nil, longitude: nil),
            spot(order: 3, latitude: 35.0, longitude: nil)
        ])
        let viewModel = PostMapViewModel(repository: MockDataRepository(posts: [target]))

        #expect(viewModel.pins.map(\.order) == [1])
    }

    @Test
    func draftsHaveNoPin() {
        let published = post(title: "公開")
        let draft = post(title: "下書き", isDraft: true)
        let viewModel = PostMapViewModel(repository: MockDataRepository(posts: [published, draft]))

        #expect(viewModel.pins.allSatisfy { $0.postTitle == "公開" })
        #expect(viewModel.post(for: MapPinID(postID: draft.id, spotID: draft.spots[0].id)) == nil)
    }

    @Test
    func looksUpPostAndSpotForPin() throws {
        let target = post()
        let viewModel = PostMapViewModel(repository: MockDataRepository(posts: [target]))
        let pinID = try #require(viewModel.pins.last).id

        #expect(viewModel.post(for: pinID)?.id == target.id)
        #expect(viewModel.spot(for: pinID)?.order == 3)
    }

    @Test
    func deletedPostRemovesPinsAndLookups() throws {
        let target = post()
        let repository = MockDataRepository(posts: [target], currentUserName: "テスト")
        let viewModel = PostMapViewModel(repository: repository)
        let pinID = try #require(viewModel.pins.first).id

        repository.delete(postID: target.id)

        #expect(viewModel.pins.isEmpty)
        #expect(viewModel.post(for: pinID) == nil)
        #expect(viewModel.spot(for: pinID) == nil)
    }

    @Test
    func postTurnedIntoDraftRemovesPinsAndLookups() throws {
        let target = post()
        let repository = MockDataRepository(posts: [target], currentUserName: "テスト")
        let viewModel = PostMapViewModel(repository: repository)
        let pinID = try #require(viewModel.pins.first).id

        // 公開済みの投稿は下書きに戻せないので、同じ ID の下書きに置き換えて確かめる
        repository.delete(postID: target.id)
        try repository.saveDraft(target, isNew: true)

        #expect(viewModel.pins.isEmpty)
        #expect(viewModel.post(for: pinID) == nil)
        #expect(viewModel.spot(for: pinID) == nil)
    }

    @Test
    func toggleLikeAndStarUpdateRepository() throws {
        let target = post()
        let repository = MockDataRepository(posts: [target])
        let viewModel = PostMapViewModel(repository: repository)
        let pinID = try #require(viewModel.pins.first).id

        viewModel.toggleLike(postID: target.id)
        viewModel.toggleStar(postID: target.id)

        let updated = try #require(viewModel.post(for: pinID))
        #expect(updated.isLiked && updated.likeCount == 11)
        #expect(updated.isStarred && updated.starCount == 3)
        #expect(repository.post(id: target.id) == updated)
    }

    @Test
    func routeFollowsRankOrderOfSelectedPost() throws {
        let target = post(spots: [spot(order: 3), spot(order: 1), spot(order: 2)])
        let other = post(title: "ほかの投稿", createdAt: Date(timeIntervalSinceNow: -100))
        let viewModel = PostMapViewModel(repository: MockDataRepository(posts: [target, other]))
        let selected = try #require(viewModel.pins.first { $0.id.postID == target.id && $0.order == 3 })

        let route = viewModel.routePins(for: selected.id)
        let coordinates = viewModel.routeCoordinates(for: selected.id)

        #expect(route.map(\.order) == [1, 2, 3])
        #expect(route.allSatisfy { $0.id.postID == target.id })
        #expect(coordinates.map(\.latitude) == route.map(\.latitude))
        #expect(coordinates.map(\.longitude) == route.map(\.longitude))
    }

    @Test
    func routeSkipsSpotsWithoutCoordinate() throws {
        let target = post(spots: [
            spot(order: 1),
            spot(order: 2, latitude: nil, longitude: nil),
            spot(order: 3)
        ])
        let viewModel = PostMapViewModel(repository: MockDataRepository(posts: [target]))
        let selected = try #require(viewModel.pins.first)

        #expect(viewModel.routePins(for: selected.id).map(\.order) == [1, 3])
        #expect(viewModel.routeCoordinates(for: selected.id).count == 2)
    }

    @Test
    func routeIsEmptyWithoutSelectionOrPost() throws {
        let target = post()
        let repository = MockDataRepository(posts: [target], currentUserName: "テスト")
        let viewModel = PostMapViewModel(repository: repository)
        let pinID = try #require(viewModel.pins.first).id

        #expect(viewModel.routePins(for: nil).isEmpty)
        #expect(viewModel.routeCoordinates(for: nil).isEmpty)

        repository.delete(postID: target.id)

        #expect(viewModel.routePins(for: pinID).isEmpty)
        #expect(viewModel.neighbors(for: pinID) == .none)
    }

    @Test
    func neighborsAreAdjacentStationsOnRoute() throws {
        let target = post()
        let viewModel = PostMapViewModel(repository: MockDataRepository(posts: [target]))
        let pins = viewModel.pins
        try #require(pins.count == 3)

        #expect(viewModel.neighbors(for: pins[0].id) == MapStationNeighbors(previous: nil, next: 2))
        #expect(viewModel.neighbors(for: pins[1].id) == MapStationNeighbors(previous: 1, next: 3))
        #expect(viewModel.neighbors(for: pins[2].id) == MapStationNeighbors(previous: 2, next: nil))
    }

    @Test
    func neighborsSkipSpotsWithoutCoordinate() throws {
        let target = post(spots: [
            spot(order: 1),
            spot(order: 2, latitude: nil, longitude: nil),
            spot(order: 3)
        ])
        let viewModel = PostMapViewModel(repository: MockDataRepository(posts: [target]))
        let pins = viewModel.pins
        try #require(pins.count == 2)

        #expect(viewModel.neighbors(for: pins[0].id) == MapStationNeighbors(previous: nil, next: 3))
        #expect(viewModel.neighbors(for: pins[1].id) == MapStationNeighbors(previous: 1, next: nil))
    }

    @Test
    func singleStationHasNoNeighbors() throws {
        let target = post(spots: [spot(order: 1), spot(order: 2, latitude: nil, longitude: nil)])
        let viewModel = PostMapViewModel(repository: MockDataRepository(posts: [target]))
        let pinID = try #require(viewModel.pins.first).id

        #expect(viewModel.routePins(for: pinID).count == 1)
        #expect(viewModel.neighbors(for: pinID) == .none)
    }

    @Test
    func regionFitsAllCoordinatesWithPadding() {
        let coordinates = [
            CLLocationCoordinate2D(latitude: 33.0, longitude: 130.0),
            CLLocationCoordinate2D(latitude: 43.0, longitude: 141.0)
        ]

        let region = PostMapViewModel.region(fitting: coordinates)

        #expect(region.center.latitude == 38.0)
        #expect(region.center.longitude == 135.5)
        #expect(region.span.latitudeDelta == 10.0 * PostMapViewModel.fittingPaddingRatio)
        #expect(region.span.longitudeDelta == 11.0 * PostMapViewModel.fittingPaddingRatio)
    }

    @Test
    func regionForSingleCoordinateKeepsMinimumSpan() {
        let region = PostMapViewModel.region(fitting: [CLLocationCoordinate2D(latitude: 35.0, longitude: 139.0)])

        #expect(region.center.latitude == 35.0 && region.center.longitude == 139.0)
        #expect(region.span.latitudeDelta == PostMapViewModel.minimumSpan)
        #expect(region.span.longitudeDelta == PostMapViewModel.minimumSpan)
    }

    @Test
    func regionSpanIsCappedForFarApartCoordinates() {
        let coordinates = [
            CLLocationCoordinate2D(latitude: -80.0, longitude: -170.0),
            CLLocationCoordinate2D(latitude: 80.0, longitude: 170.0)
        ]

        let region = PostMapViewModel.region(fitting: coordinates)

        #expect(region.span.latitudeDelta == PostMapViewModel.maximumLatitudeSpan)
        #expect(region.span.longitudeDelta == PostMapViewModel.maximumLongitudeSpan)
    }

    @Test
    func initialRegionFallsBackToJapanWithoutPins() {
        let viewModel = PostMapViewModel(repository: MockDataRepository(posts: []))

        let region = viewModel.initialRegion

        #expect(region.center.latitude == PostMapViewModel.japanRegion.center.latitude)
        #expect(region.center.longitude == PostMapViewModel.japanRegion.center.longitude)
        #expect(region.span.latitudeDelta == PostMapViewModel.japanRegion.span.latitudeDelta)
    }
}
