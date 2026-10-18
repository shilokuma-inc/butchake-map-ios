//
//  ExternalMapLinkTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import Foundation
import Testing

struct ExternalMapLinkTests {
    private func spot(
        name: String = "もりもり寿し",
        address: String = "石川県金沢市",
        latitude: Double? = 36.5717,
        longitude: Double? = 136.6565
    ) -> Spot {
        Spot(order: 1, name: name, address: address, latitude: latitude, longitude: longitude, recommendation: "")
    }

    @Test
    func appleMapsWithCoordinatePinsLocationAndShowsName() {
        let url = ExternalMapLink.url(for: spot(name: "Sushi", address: ""), in: .appleMaps)

        #expect(url?.absoluteString == "https://maps.apple.com/?ll=36.5717,136.6565&q=Sushi")
    }

    @Test
    func googleMapsWithCoordinateSearchesByCoordinate() {
        let url = ExternalMapLink.url(for: spot(), in: .googleMaps)

        #expect(url?.absoluteString == "comgooglemaps://?q=36.5717,136.6565&center=36.5717,136.6565")
    }

    @Test(arguments: [(36.5717, nil), (nil, 136.6565), (nil, nil)] as [(Double?, Double?)])
    func withoutFullCoordinateSearchesByNameAndAddress(latitude: Double?, longitude: Double?) {
        let target = spot(name: "Sushi", address: "Kanazawa", latitude: latitude, longitude: longitude)

        #expect(ExternalMapLink.url(for: target, in: .appleMaps)?.absoluteString == "https://maps.apple.com/?q=Sushi%20Kanazawa")
        #expect(ExternalMapLink.url(for: target, in: .googleMaps)?.absoluteString == "comgooglemaps://?q=Sushi%20Kanazawa")
    }

    @Test
    func percentEncodesJapaneseAndReservedCharacters() throws {
        let target = spot(name: "すし&バー+α #1", address: "", latitude: nil, longitude: nil)

        let url = try #require(ExternalMapLink.url(for: target, in: .appleMaps))
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))

        #expect(url.absoluteString.contains("%26") && url.absoluteString.contains("%2B") && url.absoluteString.contains("%23"))
        #expect(components.queryItems == [URLQueryItem(name: "q", value: "すし&バー+α #1")])
    }

    @Test
    func searchQuerySkipsBlankParts() {
        #expect(ExternalMapLink.searchQuery(for: spot(name: " Sushi ", address: "")) == "Sushi")
        #expect(ExternalMapLink.searchQuery(for: spot(name: "", address: "Kanazawa")) == "Kanazawa")
    }

    @Test
    func noURLWithoutCoordinateNameOrAddress() {
        let target = spot(name: " ", address: "", latitude: nil, longitude: nil)

        #expect(ExternalMapLink.url(for: target, in: .appleMaps) == nil)
        #expect(ExternalMapLink.url(for: target, in: .googleMaps) == nil)
    }

    @Test
    func appleMapsWithCoordinateButNoNameOmitsQuery() {
        let url = ExternalMapLink.url(for: spot(name: "", address: ""), in: .appleMaps)

        #expect(url?.absoluteString == "https://maps.apple.com/?ll=36.5717,136.6565")
    }

    @Test
    func availableAppsIncludesGoogleMapsOnlyWhenInstalled() {
        #expect(ExternalMapLink.availableApps { _ in true } == [.appleMaps, .googleMaps])
        #expect(ExternalMapLink.availableApps { _ in false } == [.appleMaps])
    }

    @Test
    func checksGoogleMapsSchemeForAvailability() {
        var checkedURLs: [URL] = []

        _ = ExternalMapLink.availableApps { url in
            checkedURLs.append(url)
            return false
        }

        #expect(checkedURLs.map(\.absoluteString) == ["comgooglemaps://"])
    }
}
