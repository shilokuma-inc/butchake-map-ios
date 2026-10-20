//
//  PostDetailView.swift
//  ButchakeMap
//

import SwiftUI

/// 投稿詳細（B-2: 都市の駅名標・3 スポットを路線図の駅として縦に並べる・ぶっちゃけコメントは駅の掲示板）。
/// 自分の投稿はツールバーのメニューから編集・削除できる
struct PostDetailView: View {
    @Environment(MockDataRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    /// 編集で作成画面（シート）に開いている投稿。開いた時点の値を持ち、保存してもフォームを作り直さない
    @State private var editingPost: Post?
    @State private var isConfirmingDeletion = false
    /// 削除した投稿。詳細を閉じて戻るアニメーションの間、「投稿が見つかりません」ではなく消す前の内容を出し続ける
    @State private var deletedPost: Post?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let postID: Post.ID

    private var viewModel: PostDetailViewModel {
        PostDetailViewModel(repository: repository, postID: postID)
    }

    var body: some View {
        Group {
            if let post = viewModel.post ?? deletedPost {
                content(post: post)
            } else {
                ContentUnavailableView {
                    Label {
                        Text("Post not found")
                    } icon: {
                        EmptyStateIllustration(kind: .notFound)
                    }
                } description: {
                    Text("This post may have been deleted.")
                }
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
            VStack(alignment: .leading, spacing: 16) {
                header(post: post)
                // 削除後の戻るアニメーション中も出せるよう、Repository ではなく受け取った投稿から並べる
                RouteLine {
                    ForEach(PostDetailViewModel.orderedSpots(of: post)) { spot in
                        RouteStationRow(number: spot.order) {
                            SpotDetailCard(
                                spot: spot,
                                stampDate: PostDetailViewModel.stampDate(of: post),
                                stampPlace: PostDetailViewModel.stampPlace(of: post)
                            )
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)
            .padding(.bottom)
        }
        .background(Color.paper)
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

    /// 確認の後に詳細を閉じてから削除し、一覧に戻る。
    /// 戻る間に「投稿が見つかりません」が見えないよう、消す前の投稿を deletedPost に残して出し続ける
    private func delete() {
        guard viewModel.canEditOrDelete, let post = viewModel.post else {
            return
        }
        deletedPost = post
        dismiss()
        if !viewModel.delete() {
            deletedPost = nil
        }
    }

    private func header(post: Post) -> some View {
        let sign = PostDetailViewModel.stationSignText(of: post)
        return VStack(alignment: .leading, spacing: 16) {
            StationSign(
                name: Text(verbatim: sign.name),
                english: sign.english.map { Text(verbatim: $0) },
                previous: Text(post.category.displayName),
                next: Text(post.authorType.displayName),
                nameFont: .b2Heading(size: 30, relativeTo: .largeTitle),
                nameTracking: 3.6
            )
            // 駅名標の英字と帯は飾りなので、地名（都道府県 市区町村）を 1 つの要素として読む
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(post.area))
            Text(post.title)
                .font(.b2Heading(size: 21, relativeTo: .title2))
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(4)
                .accessibilityAddTraits(.isHeader)
            // アクセシビリティの大きな文字では、横に並べると文字が 1 字ずつ折り返すので縦に積む
            stackedLayout(spacing: 8) {
                CategoryBadge(category: post.category)
                AuthorTypeBadge(authorType: post.authorType)
            }
            stackedLayout(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.b2Heading(size: 15, relativeTo: .subheadline))
                        .foregroundStyle(Color.textPrimary)
                    Text(post.createdAt, format: .dateTime.year().month().day())
                        .font(.b2Ticket(size: 13, relativeTo: .footnote))
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer(minLength: 0)
                HStack(spacing: 14) {
                    LikeButton(post: post, action: viewModel.toggleLike)
                    StarButton(post: post, action: viewModel.toggleStar)
                }
            }
        }
    }

    /// 通常は横に、アクセシビリティの大きな文字では縦（左寄せ）に並べる
    private func stackedLayout<Content: View>(spacing: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: spacing))
            : AnyLayout(HStackLayout(spacing: spacing))
        return layout(content)
    }
}

/// 詳細に並べる 1 スポットのカード（路線図の駅。写真・スポット名と住所・スタンプ「済」・駅の掲示板・マップで開く）
struct SpotDetailCard: View {
    let spot: Spot
    /// スタンプの上の日付（投稿日の「M.d」）と下の地名。Discussion #77 の Q2 のとおり、どの駅にも「済」を押す
    let stampDate: String
    let stampPlace: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let photoData = spot.photoData {
                SpotPhotoImage(data: photoData)
                    .frame(height: SpotPhotoPlaceholder.height)
                    .clipShape(.rect(cornerRadius: 4))
            }
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(spot.name)
                        .font(.b2Heading(size: 18, relativeTo: .headline))
                        .foregroundStyle(Color.textPrimary)
                    if !spot.address.isEmpty {
                        Label {
                            Text(spot.address)
                        } icon: {
                            Image(systemName: "mappin")
                        }
                        .font(.b2Text(size: 14, relativeTo: .subheadline))
                        .foregroundStyle(Color.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                // VoiceOver で番号の丸の代わりに「スポット 1」と読み、続けて名前と住所を読む
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Spot \(spot.order)"))
                .accessibilityValue(Text(verbatim: [spot.name, spot.address].filter { !$0.isEmpty }.joined(separator: ", ")))
                StampMark(top: stampDate, main: "済", bottom: stampPlace, size: 56)
            }
            if !spot.recommendation.isEmpty {
                NoticeBoard(label: Text("Honest Comment"), text: Text(spot.recommendation))
            }
            OpenInMapsButton(spot: spot)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.surface, in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.cardBorder, lineWidth: 1)
        }
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
                .buttonStyle(.b2Secondary)
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
        stampDate: "10.18",
        stampPlace: "台東区"
    )
    .padding()
    .background(Color.paper)
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
        stampDate: "10.18",
        stampPlace: "台東区"
    )
    .padding()
    .background(Color.paper)
    .environment(MockDataRepository.preview)
}

#Preview("削除済み") {
    NavigationStack {
        PostDetailView(postID: UUID())
    }
    .environment(MockDataRepository.preview)
}
