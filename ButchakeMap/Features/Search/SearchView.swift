//
//  SearchView.swift
//  ButchakeMap
//

import SwiftUI

/// 検索タブ（フリーワード・都道府県・カテゴリで公開済みの投稿を絞り込む）
struct SearchView: View {
    @Environment(MockDataRepository.self) private var repository
    @State private var filter = SearchFilter()

    private var viewModel: SearchViewModel {
        SearchViewModel(repository: repository)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    prefectureMenu
                    categoryChips
                    results
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Text("Search"))
            .searchable(
                text: $filter.keyword,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("Title or spot name")
            )
            .postDetailDestination()
            .onChange(of: viewModel.prefectures) { _, prefectures in
                // 選んでいた都道府県の投稿が削除・下書きに戻されたら、候補から消えるので選択を外す
                if let prefecture = filter.prefecture, !prefectures.contains(prefecture) {
                    filter.prefecture = nil
                }
            }
        }
    }

    private var prefectureMenu: some View {
        HStack {
            Label("Prefecture", systemImage: "mappin.and.ellipse")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Picker(selection: $filter.prefecture) {
                Text("All Prefectures")
                    .tag(String?.none)
                ForEach(viewModel.prefectures, id: \.self) { prefecture in
                    Text(verbatim: prefecture)
                        .tag(String?.some(prefecture))
                }
            } label: {
                Text("Prefecture")
            }
            .pickerStyle(.menu)
            .tint(Color.brandPrimary)
        }
        .padding(.horizontal)
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(
                    title: "All",
                    symbolName: "square.grid.2x2",
                    isSelected: filter.categories.isEmpty
                ) {
                    filter.categories = []
                }
                ForEach(Category.allCases) { category in
                    CategoryChip(
                        title: category.displayName,
                        symbolName: category.symbolName,
                        isSelected: filter.categories.contains(category)
                    ) {
                        filter.toggle(category)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var results: some View {
        let posts = viewModel.results(for: filter)
        if repository.publishedPosts.isEmpty {
            ContentUnavailableView("No posts yet", systemImage: "tray")
        } else if posts.isEmpty {
            ContentUnavailableView {
                Label("No Results", systemImage: "magnifyingglass")
            } description: {
                Text("Try a different keyword, prefecture, or category.")
            } actions: {
                Button("Clear Filters") {
                    filter = SearchFilter()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brandPrimary)
            }
        } else {
            ForEach(posts) { post in
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
}

/// カテゴリの絞り込みのチップ。選択中は塗りつぶす
struct CategoryChip: View {
    let title: LocalizedStringResource
    let symbolName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text(title)
            } icon: {
                Image(systemName: symbolName)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? Color.white : Color.brandAccent)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.brandAccent : Color.brandAccent.opacity(0.15), in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    SearchView()
        .environment(MockDataRepository.preview)
}

#Preview("投稿なし") {
    SearchView()
        .environment(MockDataRepository(posts: []))
}
