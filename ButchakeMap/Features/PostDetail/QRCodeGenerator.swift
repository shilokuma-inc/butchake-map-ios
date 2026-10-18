//
//  QRCodeGenerator.swift
//  ButchakeMap
//
//  シェアカードに載せる QR コードの生成と、QR に入れる投稿 URL の組み立て
//

import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

nonisolated enum QRCodeGenerator {
    /// 誤り訂正レベル（L / M / Q / H）。カードに縮小して載せても読めるよう M にする
    static let correctionLevel = "M"

    /// 文字列を QR コードの画像にする。1 モジュールを scale ピクセルの正方形に拡大する（失敗したら nil）
    static func image(for message: String, scale: CGFloat = 10) -> CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(message.utf8)
        filter.correctionLevel = correctionLevel
        guard let output = filter.outputImage else {
            return nil
        }
        // 拡大はピクセル単位の整数倍で行い、補間でぼやけないようにする
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        return CIContext().createCGImage(scaled, from: scaled.extent)
    }
}

extension Post {
    /// シェア用のダミーのドメイン（本番の URL が決まったら差し替える）
    nonisolated static let shareBaseURL = URL(string: "https://butchake-map.example/posts")!

    /// QR コードに入れる投稿の URL（`https://butchake-map.example/posts/<id>`）
    nonisolated var shareURL: URL {
        Self.shareBaseURL.appending(path: id.uuidString)
    }
}
