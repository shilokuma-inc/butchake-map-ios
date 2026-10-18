//
//  PostDetailView.swift
//  ButchakeMap
//

import SwiftUI

/// 投稿詳細（3 スポットとぶっちゃけコメント）
struct PostDetailView: View {
    @Environment(MockDataRepository.self) private var repository
    let postID: Post.ID

    private var viewModel: PostDetailViewModel {
        PostDetailViewModel(repository: repository, postID: postID)
    }

    var body: some View {
        Group {
            if let post = viewModel.post {
                content(post: post)
            } else {
                ContentUnavailableView(
                    "Post not found",
                    systemImage: "exclamationmark.magnifyingglass",
                    description: Text("This post may have been deleted.")
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func content(post: Post) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header(post: post)
                ForEach(viewModel.spots) { spot in
                    SpotDetailCard(spot: spot, category: post.category)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func header(post: Post) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(post.title)
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
            Label(post.area, systemImage: "mappin.and.ellipse")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                CategoryBadge(category: post.category)
                AuthorTypeBadge(authorType: post.authorType)
            }
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.footnote.weight(.semibold))
                    Text(post.createdAt, format: .dateTime.year().month().day())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                LikeButton(post: post, action: viewModel.toggleLike)
                StarButton(post: post, action: viewModel.toggleStar)
            }
        }
    }
}

/// 詳細に並べる 1 スポットのカード
struct SpotDetailCard: View {
    let spot: Spot
    let category: Category

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SpotPhotoPlaceholder(category: category)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "\(spot.order).circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.brandPrimary)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(spot.name)
                        .font(.headline)
                    if !spot.address.isEmpty {
                        Text(spot.address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .accessibilityElement(children: .combine)
            if !spot.recommendation.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Honest Comment")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.brandAccent)
                    Text(spot.recommendation)
                        .font(.body)
                }
            }
        }
        .cardStyle()
    }
}

/// 写真の無いスポットに出すカテゴリのプレースホルダー
struct SpotPhotoPlaceholder: View {
    let category: Category

    var body: some View {
        Image(systemName: category.symbolName)
            .font(.system(size: 40))
            .foregroundStyle(Color.brandAccent)
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(Color.brandAccent.opacity(0.12), in: .rect(cornerRadius: 12))
            .accessibilityHidden(true)
    }
}

#Preview {
    let repository = MockDataRepository.preview
    return NavigationStack {
        PostDetailView(postID: repository.publishedPosts[0].id)
    }
    .environment(repository)
}

#Preview("削除済み") {
    NavigationStack {
        PostDetailView(postID: UUID())
    }
    .environment(MockDataRepository.preview)
}
