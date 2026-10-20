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
        MyPageSectionPicker(selection: $section)
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
                    EmptyStateIllustration(kind: .noPosts)
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

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 16) {
            // アクセシビリティの大きな文字では、名前と自己紹介が細い列に押し込まれないよう、アイコンの下に置く
            profileLayout {
                ProfileAvatar()
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: viewModel.userName)
                        .font(.b2Heading(size: 20, relativeTo: .title3))
                        .foregroundStyle(Color.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text("Collecting honest big threes from my travels.")
                        .font(.b2Text(size: 15, relativeTo: .subheadline))
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer(minLength: 0)
            }
            // 件数の文言が 2 行に折り返しても数字の高さがそろうよう、上でそろえる
            HStack(alignment: .top) {
                ProfileStat(title: "Posts", value: viewModel.count(in: .myPosts))
                ProfileStatDivider()
                ProfileStat(title: "Saved", value: viewModel.count(in: .saved))
                ProfileStatDivider()
                ProfileStat(title: "Likes Received", value: viewModel.receivedLikeCount)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .cardStyle()
    }

    private var profileLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 16))
    }
}

/// プロフィールの数字 1 つ
private struct ProfileStat: View {
    let title: LocalizedStringKey
    let value: Int

    var body: some View {
        VStack(spacing: 2) {
            // 件数は発車標と同じドットの書体（数字の幅がそろう）
            Text(value, format: .number)
                .font(.b2Ticket(size: 22, relativeTo: .title3))
                .foregroundStyle(Color.brandPrimary)
            // 「保存した三大」「Likes Received」は文字を大きくすると 1 行に収まらないので、切らずに 3 行まで折り返す
            Text(title)
                .font(.b2Text(size: 12, relativeTo: .caption))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// プロフィールのアイコン（投稿カードのサムネイルと同じ、台紙の地にインクの人のアイコンと枠の丸）。飾りなので読み上げない
private struct ProfileAvatar: View {
    @ScaledMetric(relativeTo: .title3) private var size: CGFloat = 64

    var body: some View {
        let side = min(size, 112)
        Image(systemName: "person.fill")
            .font(.system(size: side * 0.46))
            .foregroundStyle(Color.brandPrimary)
            .frame(width: side, height: side)
            .background(Color.kraft, in: .circle)
            .overlay {
                Circle()
                    .strokeBorder(Color.brandPrimary, lineWidth: 2)
            }
            .accessibilityHidden(true)
    }
}

/// 件数の間の縦の区切り線（台紙の罫線の色）
private struct ProfileStatDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.separatorLine)
            .frame(width: 1)
            .accessibilityHidden(true)
    }
}

/// 自分の投稿 / 保存した三大 / 下書きの切り替え（B-2 のタブと同じ、白の地にインクの枠、選んだものはインクの地に白の文字）。
/// アクセシビリティの大きな文字では横に収まらないので縦に積む。
/// VoiceOver では「一覧」のまとまりの中の 3 つのボタンとして読み、選んでいるものに「選択中」を付ける
/// （.segmented の Picker を accessibilityRepresentation にすると、縦に積んだときに読み上げの枠が横並びのままになり、別の項目を選んでしまう）
private struct MyPageSectionPicker: View {
    @Binding var selection: MyPageSection

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 4))
            : AnyLayout(HStackLayout(spacing: 4))
        layout {
            ForEach(MyPageSection.allCases) { section in
                segment(section)
            }
        }
        .padding(4)
        .background(Color.surface, in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.textPrimary, lineWidth: 2)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("List"))
    }

    private func segment(_ section: MyPageSection) -> some View {
        let isSelected = selection == section
        return Button {
            selection = section
        } label: {
            Text(section.title)
                .font(.b2Heading(size: 14, relativeTo: .subheadline))
                .foregroundStyle(isSelected ? Color.surface : Color.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 32)
                .padding(.horizontal, 4)
                .background(isSelected ? Color.brandPrimary : Color.clear, in: .rect(cornerRadius: 6))
                .contentShape(.rect(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
                        .font(.b2Heading(size: 17, relativeTo: .headline))
                        .foregroundStyle(Color.textPrimary)
                } else {
                    Text("Untitled Draft")
                        .font(.b2Heading(size: 17, relativeTo: .headline))
                        .foregroundStyle(Color.textSecondary)
                }
                if !draft.area.isEmpty {
                    Text(verbatim: draft.area)
                        .font(.b2Text(size: 15, relativeTo: .subheadline))
                        .foregroundStyle(Color.textSecondary)
                }
                Text("Last saved \(draft.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.b2Text(size: 13, relativeTo: .footnote))
                    .foregroundStyle(Color.textSecondary)
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

#Preview("大きな文字") {
    MyPageView()
        .environment(MockDataRepository.preview)
        .environment(\.dynamicTypeSize, .accessibility5)
}
