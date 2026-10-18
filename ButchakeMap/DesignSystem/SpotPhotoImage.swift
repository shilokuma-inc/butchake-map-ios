//
//  SpotPhotoImage.swift
//  ButchakeMap
//

import SwiftUI
import UIKit

/// スポットの写真。縦横比を保ったまま、置いた枠いっぱいに切り抜いて出す。画像として読めないデータなら何も出さない
struct SpotPhotoImage: View {
    /// SpotPhotoProcessor で縮小・JPEG 圧縮したデータ
    let data: Data

    var body: some View {
        if let image = UIImage(data: data) {
            // 画像の大きさで枠を広げないよう、枠は Color.clear で決めて画像は overlay で重ねる
            Color.clear
                .overlay {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
                .accessibilityHidden(true)
        }
    }
}

#Preview {
    SpotPhotoImage(data: UIImage(systemName: "photo")?.pngData() ?? Data())
        .frame(width: 200, height: 140)
        .clipShape(.rect(cornerRadius: 12))
        .padding()
        .environment(MockDataRepository.preview)
}
