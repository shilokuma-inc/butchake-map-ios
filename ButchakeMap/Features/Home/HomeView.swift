//
//  HomeView.swift
//  ButchakeMap
//

import SwiftUI

/// ホームタブ（B-2: ロゴの見出し・駅名標の見出し・きっぷのカルーセル（今週のぶっちゃけ・急上昇）・台紙のフィード）
struct HomeView: View {
    @Environment(MockDataRepository.self) private var repository

    private var viewModel: HomeViewModel {
        HomeViewModel(repository: repository)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    HomeLogo()
                        .padding(.horizontal)
                    carousel(section: .weeklyPicks, posts: viewModel.weeklyPicks())
                    carousel(section: .trending, posts: viewModel.trendingPosts)
                    feed
                }
                .padding(.top, 2)
                .padding(.bottom)
            }
            .background(Color.paper)
            // 大きなタイトルの代わりにロゴを出す。ナビゲーションのタイトルは読み上げと UI テストのために残し、バーには文字を出さない
            .navigationTitle(Text("Butchake Map"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Color.clear
                        .frame(width: 1, height: 1)
                        .accessibilityHidden(true)
                }
            }
            .postDetailDestination()
        }
    }

    @ViewBuilder
    private func carousel(section: HomeSection, posts: [Post]) -> some View {
        if !posts.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(section: section)
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
                            .postCardAccessibilityActions(post: post) { viewModel.toggleStar(post) }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private var feed: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(section: .latestPosts)
            if viewModel.feedPosts.isEmpty {
                ContentUnavailableView {
                    Label {
                        Text("No posts yet")
                    } icon: {
                        EmptyStateIllustration(kind: .noPosts)
                    }
                }
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
                    .postCardAccessibilityActions(
                        post: post,
                        onLike: { viewModel.toggleLike(post) },
                        onStar: { viewModel.toggleStar(post) }
                    )
                    .padding(.horizontal)
                }
            }
        }
        // UI テストでフィードの中の投稿を探せるよう、まとまりとして識別子を付ける（中の要素はそのまま読める）
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.feed")
    }
}

/// ホームのセクション。見出しの駅名標の帯に、前後のセクションの名前を出す
enum HomeSection: CaseIterable {
    case weeklyPicks
    case trending
    case latestPosts

    var title: LocalizedStringResource {
        switch self {
        case .weeklyPicks:
            "This Week's Picks"
        case .trending:
            "Trending"
        case .latestPosts:
            "Latest Posts"
        }
    }

    /// 駅名標の英字の行（飾りの英字なので翻訳しない）
    var englishLabel: String {
        switch self {
        case .weeklyPicks:
            "THIS WEEK"
        case .trending:
            "TRENDING"
        case .latestPosts:
            "LATEST"
        }
    }

    /// 前のセクション（左の「◀ …」）。先頭は nil
    var previous: Self? {
        let all = Self.allCases
        guard let index = all.firstIndex(of: self), index > all.startIndex else {
            return nil
        }
        return all[all.index(before: index)]
    }

    /// 次のセクション（右の「… ▶」）。最後は nil
    var next: Self? {
        let all = Self.allCases
        guard let index = all.firstIndex(of: self), all.index(after: index) < all.endIndex else {
            return nil
        }
        return all[all.index(after: index)]
    }
}

/// ホームの見出しのロゴ（駅名標の形の「ぶっちゃけmap」）。VoiceOver では「Butchake Map」の見出しとして読む
struct HomeLogo: View {
    /// ロゴの高さ（モックの Mock.logo(24) と同じ大きさ）。文字の大きさの設定に合わせて大きくなる
    @ScaledMetric(relativeTo: .largeTitle) private var height: CGFloat = 52

    var body: some View {
        Image(.logo)
            .resizable()
            .scaledToFit()
            .frame(height: min(height, 104))
            .accessibilityLabel(Text("Butchake Map"))
            .accessibilityAddTraits(.isHeader)
    }
}

/// ホームの見出し（駅名標。帯に前後のセクションの名前）
private struct SectionHeader: View {
    let section: HomeSection

    var body: some View {
        StationSign(
            name: Text(section.title),
            english: Text(verbatim: section.englishLabel),
            previous: section.previous.map { Text($0.title) },
            next: section.next.map { Text($0.title) },
            isHeader: true
        )
        .padding(.horizontal)
    }
}

/// カルーセルに並べるきっぷ（路線名と投稿日・題名・「〇〇 ゆき」・カテゴリとスター）
struct HomeCarouselCard: View {
    let post: Post
    let onStar: () -> Void

    var body: some View {
        Ticket {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Butchake Line")
                    Spacer(minLength: 8)
                    Text(post.createdAt, format: .dateTime.year().month(.twoDigits).day(.twoDigits))
                }
                .ticketCaption()
                .lineLimit(1)
                Text(post.title)
                    .font(.b2Heading(size: 15, relativeTo: .subheadline))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                Text("Bound for \(post.area)")
                    .ticketRoute()
                    .lineLimit(1)
                HStack {
                    CategoryBadge(category: post.category)
                    Spacer(minLength: 8)
                    StarButton(post: post, action: onStar)
                }
            }
        }
        .frame(width: 252)
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
