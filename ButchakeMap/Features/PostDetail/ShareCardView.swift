//
//  ShareCardView.swift
//  ButchakeMap
//
//  SNS に共有するシェアカード。ImageRenderer で画像にし、ShareLink で共有する
//

import SwiftUI

/// シェアカード（タイトル・エリア・カテゴリ・3 スポット・ブランド名・投稿 URL の QR コード）
struct ShareCardView: View {
    /// カードの大きさ（pt）。SNS のフィードで切れにくい 4:5 の縦長にする
    static let size = CGSize(width: 360, height: 450)
    /// 画像にするときの倍率。360 x 450 pt を 1080 x 1350 px で書き出す
    static let renderScale: CGFloat = 3

    let post: Post

    private var spots: [Spot] {
        post.spots.sorted { $0.order < $1.order }
    }

    var body: some View {
        VStack(spacing: 0) {
            brandHeader
            VStack(alignment: .leading, spacing: 16) {
                summary
                spotList
                Spacer(minLength: 0)
                footer
            }
            .padding(20)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .background(.white)
        // 共有先の見た目をそろえるため、端末の外観（ダーク）にかかわらずライトの配色で描く
        .environment(\.colorScheme, .light)
    }

    private var brandHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "map.fill")
                .accessibilityHidden(true)
            Text("Butchake Map")
                .font(.headline.weight(.heavy))
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.brandPrimary)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(post.title)
                .font(.title3.bold())
                .foregroundStyle(.black)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            HStack(spacing: 8) {
                Label(post.area, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                CategoryBadge(category: post.category)
            }
        }
    }

    private var spotList: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(spots) { spot in
                HStack(spacing: 10) {
                    Image(systemName: "\(spot.order).circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.brandPrimary)
                        .accessibilityHidden(true)
                    Text(spot.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
    }

    private var footer: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Scan to see this post")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.brandAccent)
                Text(verbatim: post.shareURL.host() ?? "")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            ShareCardQRCode(url: post.shareURL)
        }
    }
}

/// 投稿 URL の QR コード。拡大しても補間でぼやけないようにする
struct ShareCardQRCode: View {
    let url: URL
    var size: CGFloat = 96

    var body: some View {
        if let image = QRCodeGenerator.image(for: url.absoluteString) {
            Image(decorative: image, scale: 1)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }
}

/// 投稿詳細のツールバーに置く共有ボタン。シェアカードを画像にして ShareLink に渡す
struct ShareCardButton: View {
    let post: Post
    @State private var cardImage: Image?

    var body: some View {
        Group {
            if let cardImage {
                ShareLink(item: cardImage, preview: SharePreview(post.title, image: cardImage)) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            } else {
                ProgressView()
            }
        }
        // 投稿の内容が変わったら描き直す
        .task(id: post) {
            cardImage = Self.render(post: post)
        }
    }

    /// シェアカードを画像にする（ImageRenderer は MainActor で使う）
    static func render(post: Post) -> Image? {
        let renderer = ImageRenderer(content: ShareCardView(post: post))
        renderer.scale = ShareCardView.renderScale
        guard let uiImage = renderer.uiImage else {
            return nil
        }
        return Image(uiImage: uiImage)
    }
}

#Preview {
    ShareCardView(post: MockDataRepository.preview.publishedPosts[0])
        .padding()
        .background(Color(.systemGroupedBackground))
        .environment(MockDataRepository.preview)
}
