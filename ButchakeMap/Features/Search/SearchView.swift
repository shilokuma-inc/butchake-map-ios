//
//  SearchView.swift
//  ButchakeMap
//

import SwiftUI

/// 検索タブ（フリーワード・都道府県・カテゴリで公開済みの投稿を絞り込む）
struct SearchView: View {
    @Environment(MockDataRepository.self) private var repository
    @State private var filter = SearchFilter()
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
            .background(Color.paper)
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

    /// 都道府県のメニュー。アクセシビリティの大きな文字では、選んだ都道府県が 1 字ずつ折り返さないよう見出しの下に置く
    private var prefectureMenu: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout())
        return layout {
            // VoiceOver では Picker のラベルで「都道府県」と読むので、見出しの Label は読ませない（二重に読まれるため）
            Label("Prefecture", systemImage: "mappin.and.ellipse")
                .font(.b2Text(size: 15, relativeTo: .subheadline))
                .foregroundStyle(Color.textSecondary)
                .accessibilityHidden(true)
            Spacer(minLength: 0)
            // .menu の Picker は大きな文字でラベルの上下が切れるので、Menu の中に Picker を置き、ラベルは自前で出す。
            // VoiceOver では Picker と同じく「都道府県」と、選んでいる都道府県を読む
            Menu {
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
            } label: {
                HStack(spacing: 6) {
                    selectedPrefectureName
                        .multilineTextAlignment(.leading)
                    Image(systemName: "chevron.up.chevron.down")
                        .imageScale(.small)
                }
                .font(.b2Heading(size: 15, relativeTo: .subheadline))
                .foregroundStyle(Color.brandPrimary)
            }
            .accessibilityLabel(Text("Prefecture"))
            .accessibilityValue(selectedPrefectureName)
        }
        .padding(.horizontal)
    }

    /// 選んでいる都道府県（選んでいなければ「すべての都道府県」）
    private var selectedPrefectureName: Text {
        if let prefecture = filter.prefecture {
            Text(verbatim: prefecture)
        } else {
            Text("All Prefectures")
        }
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
            ContentUnavailableView {
                Label {
                    Text("No posts yet")
                } icon: {
                    EmptyStateIllustration(kind: .noPosts)
                }
            }
        } else if posts.isEmpty {
            ContentUnavailableView {
                Label {
                    Text("No Results")
                } icon: {
                    EmptyStateIllustration(kind: .notFound)
                }
            } description: {
                Text("Try a different keyword, prefecture, or category.")
            } actions: {
                Button("Clear Filters") {
                    filter = SearchFilter()
                }
                .buttonStyle(.b2Primary)
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

/// カテゴリの絞り込みのチップ（B-2 のバッジと同じ形）。
/// 選んでいないときは白の地に緑の枠と文字、選んだときは緑の地に白の文字（どちらも 5.26:1）
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
            .font(.b2Heading(size: 15, relativeTo: .subheadline))
            .foregroundStyle(isSelected ? Color.surface : Color.brandAccent)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.brandAccent : Color.surface, in: .capsule)
            .overlay {
                Capsule()
                    .strokeBorder(Color.brandAccent, lineWidth: 1.5)
            }
            .contentShape(.capsule)
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
