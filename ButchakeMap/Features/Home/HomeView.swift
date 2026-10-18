//
//  HomeView.swift
//  ButchakeMap
//

import SwiftUI

/// ホームタブ（今週のぶっちゃけ・急上昇・フィード）
struct HomeView: View {
    @Environment(MockDataRepository.self) private var repository

    private var viewModel: HomeViewModel {
        HomeViewModel(repository: repository)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    carousel(title: "This Week's Picks", posts: viewModel.weeklyPicks())
                    carousel(title: "Trending", posts: viewModel.trendingPosts)
                    feed
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Text("Butchake Map"))
            .postDetailDestination()
        }
    }

    @ViewBuilder
    private func carousel(title: LocalizedStringKey, posts: [Post]) -> some View {
        if !posts.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: title)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(posts) { post in
                            NavigationLink(value: PostDestination(postID: post.id)) {
                                HomeCarouselCard(
                                    post: post,
                                    onStar: { viewModel.toggleStar(post) }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private var feed: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Latest Posts")
            if viewModel.feedPosts.isEmpty {
                ContentUnavailableView("No posts yet", systemImage: "tray")
            } else {
                ForEach(viewModel.feedPosts) { post in
                    NavigationLink(value: PostDestination(postID: post.id)) {
                        PostCardView(
                            post: post,
                            onLike: { viewModel.toggleLike(post) },
                            onStar: { viewModel.toggleStar(post) }
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
            }
        }
    }
}

/// ホームの見出し
private struct SectionHeader: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(.title3.bold())
            .padding(.horizontal)
            .accessibilityAddTraits(.isHeader)
    }
}

/// カルーセルに並べる小さめのカード
struct HomeCarouselCard: View {
    let post: Post
    let onStar: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                CategoryThumbnail(category: post.category, size: 44)
                Spacer(minLength: 0)
                StarButton(post: post, action: onStar)
            }
            Text(post.title)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)
            Text(post.area)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            CategoryBadge(category: post.category)
        }
        .frame(width: 220, alignment: .leading)
        .cardStyle()
    }
}

#Preview {
    HomeView()
        .environment(MockDataRepository.preview)
}

#Preview("投稿なし") {
    HomeView()
        .environment(MockDataRepository(posts: []))
}
