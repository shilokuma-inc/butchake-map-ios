//
//  MyPageView.swift
//  ButchakeMap
//

import SwiftUI

/// マイページタブ（プロフィールと、自分の投稿 / 保存した三大 / 下書きの切り替え）
struct MyPageView: View {
    @Environment(MockDataRepository.self) private var repository
    @State private var section: MyPageSection = .myPosts

    private var viewModel: MyPageViewModel {
        MyPageViewModel(repository: repository, section: section)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ProfileHeader(viewModel: viewModel)
                        .padding(.horizontal)
                    sectionPicker
                    content
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Text("My Page"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label {
                            Text("Settings")
                        } icon: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
            }
            .postDetailDestination()
        }
    }

    private var sectionPicker: some View {
        Picker(selection: $section) {
            ForEach(MyPageSection.allCases) { section in
                Text(section.title)
                    .tag(section)
            }
        } label: {
            Text("List")
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    @ViewBuilder
    private var content: some View {
        let posts = viewModel.posts
        if posts.isEmpty {
            ContentUnavailableView {
                Label {
                    Text(section.emptyTitle)
                } icon: {
                    Image(systemName: section.emptySymbolName)
                }
            } description: {
                Text(section.emptyDescription)
            }
        } else if section == .drafts {
            // 下書きを作成画面で開いて編集する・スワイプで削除するのは次のタスクで入れる。今は一覧に出すだけ
            ForEach(posts) { draft in
                DraftRow(draft: draft)
                    .padding(.horizontal)
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

/// アイコン・ニックネーム・自己紹介と、投稿数・保存数・もらったいいねの数
private struct ProfileHeader: View {
    let viewModel: MyPageViewModel

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.brandPrimary)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: viewModel.userName)
                        .font(.title3.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text("Collecting honest big threes from my travels.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            HStack {
                ProfileStat(title: "Posts", value: viewModel.count(in: .myPosts))
                Divider()
                ProfileStat(title: "Saved", value: viewModel.count(in: .saved))
                Divider()
                ProfileStat(title: "Likes Received", value: viewModel.receivedLikeCount)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .cardStyle()
    }
}

/// プロフィールの数字 1 つ
private struct ProfileStat: View {
    let title: LocalizedStringKey
    let value: Int

    var body: some View {
        VStack(spacing: 2) {
            Text(value, format: .number)
                .font(.headline)
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// 下書きの一覧の 1 行。タイトル未入力なら「無題の下書き」と出す
private struct DraftRow: View {
    let draft: Post

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CategoryThumbnail(category: draft.category, size: 44)
            VStack(alignment: .leading, spacing: 4) {
                if let title = MyPageViewModel.draftTitle(of: draft) {
                    Text(verbatim: title)
                        .font(.headline)
                } else {
                    Text("Untitled Draft")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                if !draft.area.isEmpty {
                    Text(verbatim: draft.area)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text("Last saved \(draft.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    MyPageView()
        .environment(MockDataRepository.preview)
}

#Preview("投稿なし") {
    MyPageView()
        .environment(MockDataRepository(posts: []))
}
