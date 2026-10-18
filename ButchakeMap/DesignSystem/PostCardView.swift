//
//  PostCardView.swift
//  ButchakeMap
//

import SwiftUI

/// フィード・検索・マイページに並べる投稿カード
struct PostCardView: View {
    let post: Post
    let onLike: () -> Void
    let onStar: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                CategoryThumbnail(category: post.category)
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    Text(post.area)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 8) {
                CategoryBadge(category: post.category)
                AuthorTypeBadge(authorType: post.authorType)
            }
            VStack(alignment: .leading, spacing: 4) {
                ForEach(post.spots) { spot in
                    SpotNameRow(spot: spot)
                }
            }
            HStack(spacing: 16) {
                Text(post.authorName)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                LikeButton(post: post, action: onLike)
                StarButton(post: post, action: onStar)
            }
        }
        .cardStyle()
    }
}

/// 番号付きのスポット名の 1 行
struct SpotNameRow: View {
    let spot: Spot

    var body: some View {
        Label {
            Text(spot.name)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(1)
        } icon: {
            Image(systemName: "\(spot.order).circle.fill")
                .foregroundStyle(Color.brandPrimary)
        }
    }
}

/// 写真の代わりに出すカテゴリのアイコン
struct CategoryThumbnail: View {
    let category: Category
    var size: CGFloat = 56

    var body: some View {
        Image(systemName: category.symbolName)
            .font(.system(size: size * 0.4))
            .foregroundStyle(Color.brandAccent)
            .frame(width: size, height: size)
            .background(Color.brandAccent.opacity(0.12), in: .rect(cornerRadius: 12))
            .accessibilityHidden(true)
    }
}

/// いいねの切り替えボタン（件数つき）
struct LikeButton: View {
    let post: Post
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text(post.likeCount, format: .number)
            } icon: {
                Image(systemName: post.isLiked ? "heart.fill" : "heart")
            }
            .font(.subheadline)
            .foregroundStyle(post.isLiked ? Color.pink : Color.secondary)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(Text("Like"))
        .accessibilityValue(Text(post.likeCount, format: .number))
        .accessibilityAddTraits(post.isLiked ? .isSelected : [])
    }
}

/// スター（保存）の切り替えボタン（件数つき）
struct StarButton: View {
    let post: Post
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text(post.starCount, format: .number)
            } icon: {
                Image(systemName: post.isStarred ? "star.fill" : "star")
            }
            .font(.subheadline)
            .foregroundStyle(post.isStarred ? Color.yellow : Color.secondary)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(Text("Save"))
        .accessibilityValue(Text(post.starCount, format: .number))
        .accessibilityAddTraits(post.isStarred ? .isSelected : [])
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(MockData.posts().filter { !$0.isDraft }) { post in
                PostCardView(post: post, onLike: {}, onStar: {})
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .environment(MockDataRepository.preview)
}
