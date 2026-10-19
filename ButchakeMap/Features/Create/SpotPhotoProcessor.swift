//
//  SpotPhotoProcessor.swift
//  ButchakeMap
//
//  スポットの写真の読み込み（PhotosPicker で選んだ項目）と、メモリ上に持つための縮小・JPEG 圧縮
//

import PhotosUI
import SwiftUI
import UIKit

nonisolated enum SpotPhotoProcessor {
    /// 縮小後の長い辺の最大ピクセル数。詳細の写真（画面幅いっぱい）を 3x の端末で表示しても粗くならない程度
    static let maxPixelSize: CGFloat = 1_080
    /// JPEG の圧縮品質（0〜1）
    static let compressionQuality: CGFloat = 0.7

    /// 選んだ項目を読み込み、縮小・JPEG 圧縮したデータにする（失敗したら nil）。重い縮小は MainActor の外で行う
    @concurrent
    static func loadJPEGData(from item: PhotosPickerItem) async -> Data? {
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            return nil
        }
        return jpegData(from: data)
    }

    /// 画像のデータを、長い辺が maxPixelSize 以下になるよう縮小して JPEG にする。小さい画像は大きさを変えずに JPEG にする。
    /// 描き直すので向き（EXIF の Orientation）は画素に反映され、位置情報などのメタデータは残らない。画像として読めなければ nil
    static func jpegData(
        from data: Data,
        maxPixelSize: CGFloat = maxPixelSize,
        compressionQuality: CGFloat = compressionQuality
    ) -> Data? {
        guard let image = UIImage(data: data), image.size.width > 0, image.size.height > 0 else {
            return nil
        }
        let size = scaledSize(for: image.size, maxPixelSize: maxPixelSize)
        let format = UIGraphicsImageRendererFormat()
        // 端末の画面倍率ではなく 1 ピクセル = 1 pt で描き、size をそのままピクセル数にする
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.jpegData(withCompressionQuality: compressionQuality) { context in
            // JPEG は透過を持てないので、透過のある画像（PNG など）は白の上に描く
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// 縦横比を保ったまま、長い辺が maxPixelSize 以下になる大きさ（整数ピクセルに丸める）。収まっていればそのまま
    static func scaledSize(for size: CGSize, maxPixelSize: CGFloat) -> CGSize {
        let longSide = max(size.width, size.height)
        guard longSide > maxPixelSize else {
            return CGSize(width: size.width.rounded(), height: size.height.rounded())
        }
        let ratio = maxPixelSize / longSide
        return CGSize(
            width: max((size.width * ratio).rounded(), 1),
            height: max((size.height * ratio).rounded(), 1)
        )
    }
}
