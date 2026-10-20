//
//  PostCardView.swift
//  ButchakeMap
//

import SwiftUI

/// フィード・検索・マイページに並べる投稿カード（B-2: スタンプラリーの台紙。3 つのスポットと、投稿日のスタンプ）
struct PostCardView: View {
    let post: Post
    let onLike: () -> Void
    let onStar: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                PostThumbnail(post: post)
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.title)
                        .font(.b2Heading(size: 17, relativeTo: .headline))
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text(post.area)
                        .font(.b2Text(size: 15, relativeTo: .subheadline))
                        .foregroundStyle(Color.textSecondary)
                }
                // 題名は省略せず折り返す（横の並びの中で 1 行に縮められないように）
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            stackedLayout(spacing: 8) {
                CategoryBadge(category: post.category)
                AuthorTypeBadge(authorType: post.authorType)
            }
            stackedLayout(spacing: 10) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(post.spots) { spot in
                        SpotNameRow(spot: spot)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                // 台紙に押した投稿日のスタンプ（上は年、真ん中は「M.d」、下は市区町村）。飾りなので読み上げない
                StampMark(
                    top: Self.stampYear(of: post),
                    main: PostDetailViewModel.stampDate(of: post),
                    bottom: PostDetailViewModel.stampPlace(of: post)
                )
            }
            HStack(spacing: 16) {
                Text(post.authorName)
                    .font(.b2Text(size: 13, relativeTo: .footnote))
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                LikeButton(post: post, action: onLike)
                StarButton(post: post, action: onStar)
            }
        }
        .cardStyle()
    }

    /// 投稿日の年（スタンプの上の小さな文字。端末のカレンダー）
    static func stampYear(of post: Post, calendar: Calendar = .current) -> String {
        String(calendar.component(.year, from: post.createdAt))
    }

    /// 通常は横に、アクセシビリティの大きな文字では縦（左寄せ）に並べる
    private func stackedLayout<Content: View>(spacing: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: spacing))
            : AnyLayout(HStackLayout(spacing: spacing))
        return layout(content)
    }
}

/// 番号付きのスポット名の 1 行（路線図の駅の番号の丸と名前）
struct SpotNameRow: View {
    let spot: Spot

    var body: some View {
        HStack(spacing: 8) {
            RouteRankBadge(number: spot.order, style: .compact)
            Text(spot.name)
                .font(.b2Text(size: 15, relativeTo: .subheadline))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
        }
    }
}

/// 投稿カードのサムネイル。スポットの写真があれば 1 枚目を、無ければカテゴリのアイコンを出す（B-2: インクの枠の丸）
struct PostThumbnail: View {
    let post: Post
    var size: CGFloat = 56

    var body: some View {
        if let photoData = post.coverPhotoData {
            SpotPhotoImage(data: photoData)
                .frame(width: size, height: size)
                .clipShape(.circle)
                .overlay {
                    Circle()
                        .strokeBorder(Color.brandPrimary, lineWidth: 2)
                }
        } else {
            CategoryThumbnail(category: post.category, size: size)
        }
    }
}

/// 写真の代わりに出すカテゴリのアイコン（台紙の地にインクのアイコンと枠の丸）
struct CategoryThumbnail: View {
    let category: Category
    var size: CGFloat = 56

    var body: some View {
        Image(systemName: category.symbolName)
            .font(.system(size: size * 0.42))
            .foregroundStyle(Color.brandPrimary)
            .frame(width: size, height: size)
            .background(Color.kraft, in: .circle)
            .overlay {
                Circle()
                    .strokeBorder(Color.brandPrimary, lineWidth: 2)
            }
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
            .font(.b2Heading(size: 15, relativeTo: .subheadline))
            .foregroundStyle(post.isLiked ? Color.brandPrimary : Color.textPrimary)
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
            .font(.b2Heading(size: 15, relativeTo: .subheadline))
            .foregroundStyle(post.isStarred ? Color.brandPrimary : Color.textPrimary)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(Text("Save"))
        .accessibilityValue(Text(post.starCount, format: .number))
        .accessibilityAddTraits(post.isStarred ? .isSelected : [])
    }
}

/// カードを NavigationLink で包むと、VoiceOver ではカード全体が 1 つのリンクになり中のボタンに個別に届かない。
/// そのため、いいね・スターをリンクのカスタムアクション（ローターの「アクション」）としても出す
struct PostCardAccessibilityActions: ViewModifier {
    let post: Post
    /// nil ならいいねのアクションを出さない（いいねボタンの無いカード用）
    let onLike: (() -> Void)?
    let onStar: () -> Void

    func body(content: Content) -> some View {
        if let onLike {
            content
                .accessibilityAction(named: post.isLiked ? Text("Remove Like") : Text("Like"), onLike)
                .accessibilityAction(named: post.isStarred ? Text("Remove from Saved") : Text("Save"), onStar)
        } else {
            content
                .accessibilityAction(named: post.isStarred ? Text("Remove from Saved") : Text("Save"), onStar)
        }
    }
}

extension View {
    /// NavigationLink で包んだ投稿カードに、いいね・スターの VoiceOver のアクションを付ける（リンクの外側に付ける）
    func postCardAccessibilityActions(post: Post, onLike: (() -> Void)? = nil, onStar: @escaping () -> Void) -> some View {
        modifier(PostCardAccessibilityActions(post: post, onLike: onLike, onStar: onStar))
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
    .background(Color.paper)
    .environment(MockDataRepository.preview)
}
