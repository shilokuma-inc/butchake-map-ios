//
//  EmptyStateIllustration.swift
//  ButchakeMap
//

import SwiftUI

/// 空の状態（ContentUnavailableView）に出す B-2 のイラスト。飾りなので VoiceOver では読み上げない
struct EmptyStateIllustration: View {
    enum Kind {
        /// まだ投稿がない（スタンプ帳の台紙。最初の 1 こを押す欄が空いている）
        case noPosts
        /// 見つからない（駅名が「？」の駅名標）
        case notFound

        var resource: ImageResource {
            switch self {
            case .noPosts:
                .emptyPosts
            case .notFound:
                .emptySearch
            }
        }
    }

    /// イラストの幅（元の SVG は 320x240）。文字の大きさの設定に合わせて大きくなるが、
    /// 大きな文字では見出しと説明を画面に残すため maxWidth で止める
    @ScaledMetric(relativeTo: .title) private var width: CGFloat = 160
    private static let maxWidth: CGFloat = 220

    let kind: Kind

    var body: some View {
        Image(kind.resource)
            .resizable()
            .scaledToFit()
            .frame(width: min(width, Self.maxWidth))
            .accessibilityHidden(true)
    }
}

#Preview("まだ投稿がない") {
    ContentUnavailableView {
        Label {
            Text("No posts yet")
        } icon: {
            EmptyStateIllustration(kind: .noPosts)
        }
    }
    .background(Color.paper)
}

#Preview("見つからない（大きな文字）") {
    ContentUnavailableView {
        Label {
            Text("No Results")
        } icon: {
            EmptyStateIllustration(kind: .notFound)
        }
    } description: {
        Text("Try a different keyword, prefecture, or category.")
    }
    .background(Color.paper)
    .environment(\.dynamicTypeSize, .accessibility5)
}
