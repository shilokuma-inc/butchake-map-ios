//
//  PostDetailView.swift
//  ButchakeMap
//

import SwiftUI

/// 投稿詳細（3 スポットとぶっちゃけコメント）。自分の投稿はツールバーのメニューから編集・削除できる
struct PostDetailView: View {
    @Environment(MockDataRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    /// 編集で作成画面（シート）に開いている投稿。開いた時点の値を持ち、保存してもフォームを作り直さない
    @State private var editingPost: Post?
    @State private var isConfirmingDeletion = false
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
                .navigationTitle(Text("Post Details"))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        // シート・確認は Group に付け、削除で投稿が見つからなくなっても出し続ける
        .sheet(item: $editingPost) { post in
            editor(post: post)
        }
        .confirmationDialog("Delete this post?", isPresented: $isConfirmingDeletion, titleVisibility: .visible) {
            Button(role: .destructive, action: delete) {
                Text("Delete")
            }
        } message: {
            Text("This can't be undone.")
        }
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
        .navigationTitle(post.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareCardButton(post: post)
            }
            if viewModel.canEditOrDelete {
                ToolbarItem(placement: .topBarTrailing) {
                    ownerMenu
                }
            }
        }
    }

    /// 自分の投稿にだけ出す編集・削除のメニュー
    private var ownerMenu: some View {
        Menu {
            Button {
                editingPost = viewModel.editablePost
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                isConfirmingDeletion = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Label("More", systemImage: "ellipsis.circle")
        }
    }

    /// 編集の作成画面。都道府県の選択で push するので NavigationStack に入れる。
    /// 入力を誤って失わないよう、下にスワイプでは閉じずキャンセルで閉じる
    private func editor(post: Post) -> some View {
        NavigationStack {
            PostFormView(post: post) { outcome in
                if PostDetailViewModel.closesEditor(after: outcome) {
                    editingPost = nil
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        editingPost = nil
                    } label: {
                        Text("Cancel")
                    }
                }
            }
        }
        .interactiveDismissDisabled()
        .environment(repository)
    }

    /// 確認の後に削除し、消せたら詳細を閉じて一覧に戻る
    private func delete() {
        if viewModel.delete() {
            dismiss()
        }
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
            if let photoData = spot.photoData {
                SpotPhotoImage(data: photoData)
                    .frame(height: SpotPhotoPlaceholder.height)
                    .clipShape(.rect(cornerRadius: 12))
            } else {
                SpotPhotoPlaceholder(category: category)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "\(spot.order).circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.brandPrimary)
                    // VoiceOver で ①②③ の順番を「スポット 1」のように読ませる
                    .accessibilityLabel(Text("Spot \(spot.order)"))
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
            OpenInMapsButton(spot: spot)
        }
        .cardStyle()
    }
}

/// スポットを外部のマップアプリで開くボタン。Google Maps アプリがあれば Apple マップと選ばせる
struct OpenInMapsButton: View {
    @Environment(\.openURL) private var openURL
    @State private var isChoosingApp = false
    let spot: Spot

    var body: some View {
        // 座標も名前も住所も無く URL を作れないスポットにはボタンを出さない
        if ExternalMapLink.url(for: spot, in: .appleMaps) != nil {
            Button("Open in Maps", systemImage: "map", action: open)
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.bordered)
                .tint(Color.brandPrimary)
                // 3 スポットのボタンが同じ読み上げにならないよう、VoiceOver ではスポット名も読む
                .accessibilityLabel(accessibilityLabel)
                .confirmationDialog("Open in Maps", isPresented: $isChoosingApp, titleVisibility: .visible) {
                    ForEach(ExternalMapApp.allCases) { app in
                        Button {
                            open(in: app)
                        } label: {
                            Text(app.displayName)
                        }
                    }
                }
        }
    }

    /// VoiceOver で読む「<スポット名> をマップで開く」。名前が無ければ「マップで開く」
    private var accessibilityLabel: Text {
        let name = spot.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? Text("Open in Maps") : Text("Open \(name) in Maps")
    }

    private func open() {
        let apps = ExternalMapLink.availableApps { UIApplication.shared.canOpenURL($0) }
        if apps.count > 1 {
            isChoosingApp = true
        } else {
            open(in: .appleMaps)
        }
    }

    private func open(in app: ExternalMapApp) {
        guard let url = ExternalMapLink.url(for: spot, in: app) else {
            return
        }
        openURL(url)
    }
}

/// 写真の無いスポットに出すカテゴリのプレースホルダー
struct SpotPhotoPlaceholder: View {
    /// 写真・プレースホルダーの高さ。写真があるときも同じ高さで出す
    static let height: CGFloat = 140

    let category: Category

    var body: some View {
        Image(systemName: category.symbolName)
            .font(.system(size: 40))
            .foregroundStyle(Color.brandAccent)
            .frame(maxWidth: .infinity)
            .frame(height: Self.height)
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

#Preview("座標の無いスポット") {
    SpotDetailCard(
        spot: Spot(order: 1, name: "レトロ喫茶 ぶっちゃけ", address: "東京都台東区", recommendation: "固めのプリンが名物。"),
        category: .gourmet
    )
    .padding()
    .background(Color(.systemGroupedBackground))
    .environment(MockDataRepository.preview)
}

#Preview("自分の投稿（編集・削除できる）") {
    let repository = MockDataRepository.preview
    return NavigationStack {
        PostDetailView(postID: repository.myPosts[0].id)
    }
    .environment(repository)
}

#Preview("写真のあるスポット") {
    SpotDetailCard(
        spot: Spot(
            order: 1,
            name: "レトロ喫茶 ぶっちゃけ",
            address: "東京都台東区",
            recommendation: "固めのプリンが名物。",
            photoData: UIImage(systemName: "cup.and.saucer.fill")?.pngData()
        ),
        category: .gourmet
    )
    .padding()
    .background(Color(.systemGroupedBackground))
    .environment(MockDataRepository.preview)
}

#Preview("削除済み") {
    NavigationStack {
        PostDetailView(postID: UUID())
    }
    .environment(MockDataRepository.preview)
}
