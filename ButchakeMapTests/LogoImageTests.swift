//
//  LogoImageTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import Testing
import UIKit

/// B-2 のロゴ（Assets.xcassets の Logo。Tools/make_logo_svg.py で書き出した SVG）
struct LogoImageTests {
    /// ロゴがアプリのバンドルから読め、元の SVG の viewBox と同じ縦横比（528.82x131.34）になっている
    @Test
    func logoLoadsFromBundle() throws {
        let image = try #require(UIImage(named: "Logo", in: .main, compatibleWith: nil), "Logo が読めない")
        #expect(abs(image.size.width / image.size.height - 528.82 / 131.34) < 0.01)
    }

    /// ダークでもロゴが読め、ライトと同じ縦横比になっている（logo-dark.svg は色だけが違う）
    @Test
    func darkLogoHasSameAspectRatio() throws {
        let dark = UITraitCollection(userInterfaceStyle: .dark)
        let image = try #require(UIImage(named: "Logo", in: .main, compatibleWith: dark), "ダークの Logo が読めない")
        #expect(abs(image.size.width / image.size.height - 528.82 / 131.34) < 0.01)
    }

    /// ダークでは、ロゴの地がライトの白ではなくダークの白の地（Surface）になる（白い地のまま浮かないように）
    @Test
    func darkLogoUsesDarkSurface() throws {
        let light = try #require(UIImage(named: "Logo", in: .main, compatibleWith: UITraitCollection(userInterfaceStyle: .light)))
        let dark = try #require(UIImage(named: "Logo", in: .main, compatibleWith: UITraitCollection(userInterfaceStyle: .dark)))
        #expect(try backgroundPixel(of: light) == 0xFFFFFF)
        #expect(try backgroundPixel(of: dark) == 0x2A2F40)
    }

    /// ロゴの地（左端の文字の無いところ）の 1 画素の色
    private func backgroundPixel(of image: UIImage) throws -> UInt32 {
        let size = CGSize(width: 528.82, height: 131.34)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let rendered = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        let cgImage = try #require(rendered.cgImage)
        let colorSpace = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        var pixel = [UInt8](repeating: 0, count: 4)
        let drawn = pixel.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: 1,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return false
            }
            // 左端から 6pt（枠の 2.5pt の内側）、上から 70pt（地）の 1 画素を、1x1 の context の原点に合わせて描く
            let height = CGFloat(cgImage.height)
            context.draw(cgImage, in: CGRect(x: -6, y: -(height - 70), width: CGFloat(cgImage.width), height: height))
            return true
        }
        #expect(drawn)
        return (UInt32(pixel[0]) << 16) | (UInt32(pixel[1]) << 8) | UInt32(pixel[2])
    }
}
