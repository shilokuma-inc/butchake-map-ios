//
//  ShareCardView.swift
//  ButchakeMap
//
//  SNS に共有するシェアカード。ImageRenderer で画像にし、ShareLink で共有する
//

import SwiftUI

/// シェアカード（B-2: クラフト紙の台紙に、駅名標のロゴ・題名・地名とカテゴリ・3 駅・投稿日のスタンプ・投稿 URL の QR コード）
/// スポットの写真は載せない。4:5 の限られた面積では 3 スポットの名前と QR コードを読みやすく保つことを優先する
struct ShareCardView: View {
    /// カードの大きさ（pt）。SNS のフィードで切れにくい 4:5 の縦長にする
    static let size = CGSize(width: 360, height: 450)
    /// 画像にするときの倍率。360 x 450 pt を 1080 x 1350 px で書き出す
    static let renderScale: CGFloat = 3
    /// ロゴの高さ（モックの Mock.logo(22)。ホームの Mock.logo(24) の 52pt と同じ比）
    static let logoHeight: CGFloat = 48
    /// 投稿日のスタンプの直径（投稿詳細のスタンプと同じ）
    static let stampSize: CGFloat = 56

    let post: Post

    private var spots: [Spot] {
        post.spots.sorted { $0.order < $1.order }
    }

    var body: some View {
        VStack(spacing: 0) {
            Image(.logo)
                .resizable()
                .scaledToFit()
                .frame(height: Self.logoHeight)
                .accessibilityLabel(Text("Butchake Map"))
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
            VStack(alignment: .leading, spacing: 12) {
                summary
                spotList
                Spacer(minLength: 0)
                footer
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .background(Color.kraft)
        // 画像の中は固定の大きさで描く（共有先で見た目がそろうよう、端末の文字の大きさの設定に左右されないようにする）
        .environment(\.dynamicTypeSize, .large)
        // 共有先の見た目をそろえるため、端末の外観（ダーク）にかかわらずライトの配色で描く
        .environment(\.colorScheme, .light)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(post.title)
                .font(.b2Heading(size: 20, relativeTo: .title3))
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(5)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                ShareCardAreaBadge(area: post.area)
                CategoryBadge(category: post.category)
                    // 地名が長いときは地名の側を省略し、カテゴリは切らない
                    .fixedSize()
            }
        }
    }

    /// 3 駅の一覧（白の地に台紙の枠）
    private var spotList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(spots) { spot in
                HStack(spacing: 10) {
                    RouteRankBadge(number: spot.order, style: .compact)
                    Text(spot.name)
                        .font(.b2Heading(size: 16, relativeTo: .callout))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface, in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.kraftBorder, lineWidth: 1)
        }
    }

    private var footer: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Scan to see this post")
                    .font(.b2Heading(size: 14, relativeTo: .subheadline))
                    .foregroundStyle(Color.brandPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(verbatim: post.shareURL.host() ?? "")
                    .font(.b2Heading(size: 13, relativeTo: .footnote))
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            // 台紙に押した投稿日のスタンプ（投稿詳細の駅名標のスタンプと同じ「済」）
            StampMark(
                top: PostDetailViewModel.stampDate(of: post),
                main: "済",
                bottom: PostDetailViewModel.stampPlace(of: post),
                size: Self.stampSize
            )
            ShareCardQRCode(url: post.shareURL)
                .padding(6)
                .background(Color.surface, in: .rect(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.textPrimary, lineWidth: 2)
                }
        }
    }
}

/// シェアカードの地名のバッジ（白の地に補足の文字の枠と文字。カテゴリのバッジと同じ形）。長い地名は末尾を省略する
private struct ShareCardAreaBadge: View {
    let area: String

    var body: some View {
        Label {
            Text(verbatim: area)
                .lineLimit(1)
        } icon: {
            Image(systemName: "mappin")
        }
        .font(.b2Heading(size: 13, relativeTo: .footnote))
        .foregroundStyle(Color.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 3)
        .background(Color.surface, in: .capsule)
        .overlay {
            Capsule()
                .strokeBorder(Color.textSecondary, lineWidth: 1.5)
        }
    }
}

/// 投稿 URL の QR コード。拡大しても補間でぼやけないようにする
struct ShareCardQRCode: View {
    let url: URL
    /// QR コードの一辺（モックの .qr の 84pt から、余白 6pt と枠 2pt を引いた大きさ）
    var size: CGFloat = 68

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
                    label
                }
            } else {
                // 描き終わるまで（描けなかったときも）押せない共有ボタンを出す
                Button {} label: {
                    label
                }
                .disabled(true)
            }
        }
        // カードに出す内容が変わったときだけ描き直す（いいね・スターでは描き直さない）
        .task(id: ShareCardContent(post: post)) {
            cardImage = Self.renderUIImage(post: post).map(Image.init(uiImage:))
        }
    }

    private var label: some View {
        Label("Share", systemImage: "square.and.arrow.up")
    }

    /// シェアカードを画像にする（ImageRenderer は MainActor で使う）
    static func renderUIImage(post: Post) -> UIImage? {
        let renderer = ImageRenderer(content: ShareCardView(post: post))
        renderer.scale = ShareCardView.renderScale
        return renderer.uiImage
    }
}

/// シェアカードに出す項目。これが変わったときだけカードを描き直す
private struct ShareCardContent: Hashable {
    let id: Post.ID
    let title: String
    let area: String
    let category: Category
    let spots: [Spot]
    /// 投稿日のスタンプの日付
    let createdAt: Date

    init(post: Post) {
        id = post.id
        title = post.title
        area = post.area
        category = post.category
        spots = post.spots
        createdAt = post.createdAt
    }
}

#Preview {
    ShareCardView(post: MockDataRepository.preview.publishedPosts[0])
        .padding()
        .background(Color.paper)
        .environment(MockDataRepository.preview)
}

#Preview("大きな文字（カードの中は変わらない）") {
    ShareCardView(post: MockDataRepository.preview.publishedPosts[0])
        .padding()
        .background(Color.paper)
        .environment(MockDataRepository.preview)
        .environment(\.dynamicTypeSize, .accessibility5)
}
