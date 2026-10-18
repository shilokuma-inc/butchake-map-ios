//
//  SpotPhotoProcessorTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import Foundation
import Testing
import UIKit

struct SpotPhotoProcessorTests {
    /// 指定したピクセル数の単色の PNG
    private func pngData(width: CGFloat, height: CGFloat) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        return renderer.pngData { context in
            UIColor.systemOrange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    /// データを画像として読み戻したピクセル数
    private func pixelSize(of data: Data) throws -> CGSize {
        let image = try #require(UIImage(data: data)?.cgImage)
        return CGSize(width: image.width, height: image.height)
    }

    /// JPEG の先頭のマーカー（SOI: FF D8）で始まるか
    private func isJPEG(_ data: Data) -> Bool {
        data.starts(with: [0xFF, 0xD8])
    }

    // MARK: - 縮小・圧縮

    @Test
    func largeLandscapeImageIsScaledDownToMaxPixelSize() throws {
        let data = try #require(SpotPhotoProcessor.jpegData(from: pngData(width: 3_000, height: 2_000)))

        #expect(try pixelSize(of: data) == CGSize(width: 1_080, height: 720))
        #expect(isJPEG(data))
    }

    @Test
    func largePortraitImageIsScaledDownByLongSide() throws {
        let data = try #require(SpotPhotoProcessor.jpegData(from: pngData(width: 1_000, height: 4_000)))

        #expect(try pixelSize(of: data) == CGSize(width: 270, height: 1_080))
    }

    @Test
    func smallImageKeepsItsSizeButBecomesJPEG() throws {
        let data = try #require(SpotPhotoProcessor.jpegData(from: pngData(width: 400, height: 300)))

        #expect(try pixelSize(of: data) == CGSize(width: 400, height: 300))
        #expect(isJPEG(data))
    }

    @Test
    func customMaxPixelSizeIsUsed() throws {
        let data = try #require(SpotPhotoProcessor.jpegData(from: pngData(width: 800, height: 800), maxPixelSize: 100))

        #expect(try pixelSize(of: data) == CGSize(width: 100, height: 100))
    }

    @Test(arguments: [Data(), Data("not an image".utf8), Data([0xFF, 0xD8, 0xFF, 0x00])])
    func brokenDataReturnsNil(data: Data) {
        #expect(SpotPhotoProcessor.jpegData(from: data) == nil)
    }

    // MARK: - 縮小後の大きさ

    private func scaledSize(width: CGFloat, height: CGFloat) -> CGSize {
        SpotPhotoProcessor.scaledSize(for: CGSize(width: width, height: height), maxPixelSize: 1_080)
    }

    @Test
    func sizeWithinLimitIsUnchanged() {
        #expect(scaledSize(width: 1_080, height: 1_080) == CGSize(width: 1_080, height: 1_080))
        #expect(scaledSize(width: 10, height: 20) == CGSize(width: 10, height: 20))
    }

    @Test
    func verySlenderImageKeepsAtLeastOnePixel() {
        #expect(scaledSize(width: 10_000, height: 2) == CGSize(width: 1_080, height: 1))
    }
}
