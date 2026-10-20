//
//  MyPageView.swift
//  ButchakeMap
//

import SwiftUI

/// マイページタブ（プロフィールと、自分の投稿 / 保存した三大 / 下書きの切り替え）
struct MyPageView: View {
    @Environment(MockDataRepository.self) private var repository
    @State private var section: MyPageSection = .myPosts
    /// 下書きの行は List の中で Button から push するので、遷移先をここに積む
    @State private var path = NavigationPath()

    private var viewModel: MyPageViewModel {
        MyPageViewModel(repository: repository, section: section)
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                // スワイプでの削除（.swipeActions）は List の中でしか使えないので、下書きの一覧だけ List にする
                if section == .drafts && !viewModel.posts.isEmpty {
                    draftList
                } else {
                    cardList
                }
            }
            .background(Color.paper)
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
            .navigationDestination(for: DraftDestination.self) { destination in
                DraftEditView(postID: destination.postID)
            }
        }
    }

    /// プロフィールと一覧の切り替え
    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            ProfileHeader(viewModel: viewModel)
                .padding(.horizontal)
            sectionPicker
        }
    }

    /// 自分の投稿・保存した三大の一覧（下書きが無いときの案内も出す）
    private var cardList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                header
                content
            }
            .padding(.vertical)
        }
    }

    /// 下書きの一覧。行をタップすると作成画面で開き、スワイプで削除できる
    private var draftList: some View {
        List {
            header
                .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            ForEach(viewModel.posts) { draft in
                Button {
                    path.append(DraftDestination(postID: draft.id))
                } label: {
                    DraftRow(draft: draft)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.deleteDraft(draft)
                    } label: {
                        Label {
                            Text("Delete")
                        } icon: {
                            Image(systemName: "trash")
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
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
            // 件数の文言が 2 行に折り返しても数字の高さがそろうよう、上でそろえる
            HStack(alignment: .top) {
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
            // 「保存した三大」「Likes Received」は文字を大きくすると 1 行に収まらないので、切らずに 2 行まで折り返す
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// 下書きの一覧の 1 行。タイトル未入力なら「無題の下書き」と出す。タップで編集画面を開く
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
