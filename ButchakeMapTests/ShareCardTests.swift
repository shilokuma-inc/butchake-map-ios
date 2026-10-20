//
//  ShareCardTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import CoreImage
import Foundation
import SwiftUI
import Testing

struct ShareCardTests {
    private func post(id: UUID = UUID()) -> Post {
        Post(
            id: id,
            authorName: "テスト",
            authorType: .local,
            title: "テストの三大",
            prefecture: "東京都",
            city: "千代田区",
            category: .gourmet,
            spots: (1...3).map { Spot(order: $0, name: "スポット\($0)", address: "", recommendation: "") },
            likeCount: 0,
            starCount: 0
        )
    }

    /// QR コードの画像を CIDetector で読み戻した文字列
    private func decode(_ image: CGImage) -> [String] {
        let detector = CIDetector(
            ofType: CIDetectorTypeQRCode,
            context: nil,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        )
        let features = detector?.features(in: CIImage(cgImage: image)) ?? []
        return features.compactMap { ($0 as? CIQRCodeFeature)?.messageString }
    }

    @Test
    func shareURLContainsPostID() throws {
        let id = try #require(UUID(uuidString: "6F1C2D3E-4A5B-4C6D-8E9F-0A1B2C3D4E5F"))

        #expect(post(id: id).shareURL.absoluteString == "https://butchake-map.example/posts/6F1C2D3E-4A5B-4C6D-8E9F-0A1B2C3D4E5F")
    }

    @Test
    func generatedQRCodeDecodesToShareURL() throws {
        let url = post().shareURL
        let image = try #require(QRCodeGenerator.image(for: url.absoluteString))

        #expect(decode(image) == [url.absoluteString])
    }

    @Test
    func qrCodeIsScaledByWholePixels() throws {
        let original = try #require(QRCodeGenerator.image(for: "https://butchake-map.example", scale: 1))
        let scaled = try #require(QRCodeGenerator.image(for: "https://butchake-map.example", scale: 10))

        #expect(scaled.width == original.width * 10)
        #expect(scaled.height == original.height * 10)
    }

    @Test
    @MainActor
    func rendersShareCardAtExportSize() throws {
        let image = try #require(ShareCardButton.renderUIImage(post: post())?.cgImage)

        #expect(image.width == 1_080)
        #expect(image.height == 1_350)
    }

    @Test
    @MainActor
    func renderedShareCardContainsReadableQRCode() throws {
        let target = post()
        let image = try #require(ShareCardButton.renderUIImage(post: target)?.cgImage)

        #expect(decode(image) == [target.shareURL.absoluteString])
    }

    @Test
    @MainActor
    func renderedShareCardWithLongTextContainsReadableQRCode() throws {
        var target = post()
        target.title = String(repeating: "とても長い題名", count: 10)
        target.prefecture = "和歌山県"
        target.city = String(repeating: "西牟婁郡すさみ町", count: 4)
        target.spots = (1...3).map { Spot(order: $0, name: String(repeating: "長いスポット名", count: 6), address: "", recommendation: "") }
        let image = try #require(ShareCardButton.renderUIImage(post: target)?.cgImage)

        #expect(image.width == 1_080)
        #expect(image.height == 1_350)
        #expect(decode(image) == [target.shareURL.absoluteString])
    }

    /// カードの中は文字の大きさの設定に左右されない（共有先で見た目がそろうよう、固定の大きさで描く）
    @Test
    @MainActor
    func shareCardIgnoresDynamicTypeSize() throws {
        let target = post()
        let standard = try #require(render(ShareCardView(post: target)))
        let large = try #require(render(ShareCardView(post: target).environment(\.dynamicTypeSize, .accessibility5)))

        #expect(standard == large)
    }

    @MainActor
    private func render(_ content: some View) -> Data? {
        let renderer = ImageRenderer(content: content)
        renderer.scale = ShareCardView.renderScale
        return renderer.uiImage?.pngData()
    }
}
