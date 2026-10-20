//
//  PostCreateView.swift
//  ButchakeMap
//

import MapKit
import SwiftUI

/// 投稿タブ。新しい投稿を作る
struct PostCreateView: View {
    var body: some View {
        NavigationStack {
            PostFormView(post: nil)
        }
    }
}

/// 投稿の入力フォーム。post が nil なら新規作成、あれば既存の投稿（下書き・公開済み）の編集。
/// 都道府県の選択で画面を push するので、NavigationStack の中に置く。スポットの位置はシートの地図で選ぶ
struct PostFormView: View {
    @Environment(MockDataRepository.self) private var repository
    let post: Post?
    /// 保存・公開の結果のアラートを閉じたときに呼ぶ。編集画面を閉じるかどうかは呼び出し側が決める
    var onOutcomeDismissed: (PostCreateViewModel.Outcome) -> Void = { _ in }

    var body: some View {
        PostFormContent(
            viewModel: PostCreateViewModel(post: post, repository: repository),
            onOutcomeDismissed: onOutcomeDismissed
        )
            // 違う投稿を渡されたらフォーム（ViewModel）を作り直す
            .id(post?.id)
    }
}

/// フォームの中身。ViewModel は最初に渡されたものを @State で持ち続ける
private struct PostFormContent: View {
    @State private var viewModel: PostCreateViewModel
    /// 位置を選ぶ地図を開いているスポットの番号
    @State private var locationPickerOrder: LocationPickerOrder?

    /// `.sheet(item:)` に渡すスポットの番号
    private struct LocationPickerOrder: Identifiable {
        let id: Int
    }

    let onOutcomeDismissed: (PostCreateViewModel.Outcome) -> Void

    init(viewModel: PostCreateViewModel, onOutcomeDismissed: @escaping (PostCreateViewModel.Outcome) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onOutcomeDismissed = onOutcomeDismissed
    }

    private var title: LocalizedStringKey {
        viewModel.isNew ? "New Post" : "Edit Post"
    }

    var body: some View {
        Form {
            basicInfoSection
            ForEach($viewModel.post.spots) { $spot in
                spotSection(spot: $spot)
            }
            actionSection
        }
        // B-2 の地（紙）に白の行を並べ、文字は BIZ UDPゴシック、ボタンや選択の色はインクにする
        .font(.b2Body)
        .scrollContentBackground(.hidden)
        .background(Color.paper)
        .tint(Color.brandPrimary)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(Text(title))
        .sheet(item: $locationPickerOrder) { picker in
            SpotLocationPickerView(
                order: picker.id,
                initialRegion: viewModel.locationPickerRegion(forSpot: picker.id),
                requiresMove: viewModel.locationPickerRequiresMove(forSpot: picker.id)
            ) { coordinate in
                viewModel.setLocation(coordinate, forSpot: picker.id)
            }
        }
        .alert(
            viewModel.outcome.map { Text($0.title) } ?? Text(verbatim: ""),
            isPresented: isShowingOutcome,
            presenting: viewModel.outcome
        ) { _ in
            EmptyView()
        } message: { outcome in
            if let message = outcome.message {
                Text(message)
            }
        }
    }

    private var basicInfoSection: some View {
        Section {
            textField("Title", text: $viewModel.post.title, field: .title)
            VStack(alignment: .leading, spacing: 4) {
                NavigationLink {
                    PrefectureSelectionList(selection: $viewModel.post.prefecture)
                } label: {
                    LabeledContent("Prefecture") {
                        if viewModel.post.prefecture.isEmpty {
                            Text("Not selected")
                        } else {
                            Text(verbatim: viewModel.post.prefecture)
                        }
                    }
                }
                .accessibilityIdentifier(Self.accessibilityIdentifier(for: .prefecture))
                errorText(for: .prefecture)
            }
            textField("City", text: $viewModel.post.city, field: .city)
            Picker("Category", selection: $viewModel.post.category) {
                ForEach(Category.allCases) { category in
                    Text(category.displayName)
                        .tag(category)
                }
            }
            .accessibilityIdentifier("postForm.category")
            Picker("Author Type", selection: $viewModel.post.authorType) {
                ForEach(AuthorType.allCases) { authorType in
                    Text(authorType.displayName)
                        .tag(authorType)
                }
            }
            .accessibilityIdentifier("postForm.authorType")
        } header: {
            sectionHeader(Text("Basic Info"))
        }
        .listRowBackground(Color.surface)
    }

    /// セクションの見出し（BIZ UDPゴシック Bold・文字色）。英語でも大文字にせず、書いたとおりに出す
    private func sectionHeader(_ text: Text) -> some View {
        text
            .font(.b2Heading(size: 15, relativeTo: .subheadline))
            .foregroundStyle(Color.textPrimary)
            .textCase(nil)
    }

    private func spotSection(spot: Binding<Spot>) -> some View {
        let order = spot.wrappedValue.order
        return Section {
            textField("Place Name", text: spot.name, field: .spotName(order: order))
            textField("Address", text: spot.address, field: .spotAddress(order: order))
            locationRows(spot: spot.wrappedValue)
            SpotPhotoPickerRow(
                photoData: spot.wrappedValue.photoData,
                isLoading: viewModel.loadingPhotoSpots.contains(order),
                loadFailed: viewModel.failedPhotoSpots.contains(order),
                onSelect: { item in
                    viewModel.loadPhoto(forSpot: order) {
                        await SpotPhotoProcessor.loadJPEGData(from: item)
                    }
                },
                onRemove: {
                    viewModel.removePhoto(forSpot: order)
                }
            )
            textField("Honest Comment", text: spot.recommendation, field: .spotRecommendation(order: order), axis: .vertical)
        } header: {
            // 詳細の路線図と同じ駅の番号の丸を添える（丸は読み上げず、読み上げは「スポット 1」のまま）
            HStack(spacing: 8) {
                RouteRankBadge(number: order, style: .compact)
                sectionHeader(Text("Spot \(order)"))
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
        }
        .listRowBackground(Color.surface)
    }

    /// 位置の行。未選択なら「地図で位置を選ぶ」、選択済みなら小さな地図と選び直し・解除
    @ViewBuilder
    private func locationRows(spot: Spot) -> some View {
        let order = spot.order
        if let coordinate = spot.coordinate {
            VStack(alignment: .leading, spacing: 8) {
                Label("Location selected", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Color.brandPrimary)
                SpotLocationPreview(title: spot.name, coordinate: coordinate)
            }
            Button("Change Location", systemImage: "map") {
                locationPickerOrder = LocationPickerOrder(id: order)
            }
            Button("Remove Location", systemImage: "mappin.slash", role: .destructive) {
                viewModel.clearLocation(forSpot: order)
            }
        } else {
            Button("Choose Location on Map", systemImage: "mappin.and.ellipse") {
                locationPickerOrder = LocationPickerOrder(id: order)
            }
        }
    }

    private var actionSection: some View {
        Section {
            Button(action: viewModel.publish) {
                Text("Publish")
                    .bold()
                    .frame(maxWidth: .infinity)
            }
            .disabled(viewModel.isLoadingPhoto)
            .accessibilityIdentifier("postForm.publish")
            if viewModel.showsSaveDraftButton {
                Button(action: viewModel.saveDraft) {
                    Text("Save Draft")
                        .frame(maxWidth: .infinity)
                }
                .disabled(!viewModel.canSaveDraft)
                .accessibilityIdentifier("postForm.saveDraft")
            }
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                if viewModel.isLoadingPhoto {
                    Text("Loading photos. You can publish or save once they're ready.")
                }
                if viewModel.showsRequiredErrors && !viewModel.canPublish {
                    Text("Some fields need your attention.")
                        .foregroundStyle(.red)
                }
                Text("All fields except addresses and locations are required to publish.")
            }
            .font(.b2Text(size: 13, relativeTo: .footnote))
            .foregroundStyle(Color.textSecondary)
        }
    }

    private func textField(
        _ title: LocalizedStringKey,
        text: Binding<String>,
        field: PostCreateViewModel.Field,
        axis: Axis = .horizontal
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(title, text: text, axis: axis)
                .lineLimit(axis == .vertical ? 3 : 1, reservesSpace: true)
                .accessibilityIdentifier(Self.accessibilityIdentifier(for: field))
            errorText(for: field)
        }
    }

    /// UI テストで入力欄を探す識別子（表示言語によらない）
    private static func accessibilityIdentifier(for field: PostCreateViewModel.Field) -> String {
        switch field {
        case .title:
            "postForm.title"
        case .prefecture:
            "postForm.prefecture"
        case .city:
            "postForm.city"
        case .spotName(let order):
            "postForm.spot\(order).name"
        case .spotAddress(let order):
            "postForm.spot\(order).address"
        case .spotRecommendation(let order):
            "postForm.spot\(order).comment"
        }
    }

    @ViewBuilder
    private func errorText(for field: PostCreateViewModel.Field) -> some View {
        if let error = viewModel.error(for: field) {
            Text(error.message)
                .font(.b2Text(size: 12, relativeTo: .caption))
                .foregroundStyle(.red)
        }
    }

    private var isShowingOutcome: Binding<Bool> {
        Binding {
            viewModel.outcome != nil
        } set: { isPresented in
            if !isPresented, let outcome = viewModel.outcome {
                viewModel.outcome = nil
                onOutcomeDismissed(outcome)
            }
        }
    }
}

/// 都道府県の一覧。選んだらフォームに戻る。
/// `.pickerStyle(.navigationLink)` の Picker は、iOS 26.5 では選んでも一覧から戻らなかったため、戻る処理を自前で持つ
private struct PrefectureSelectionList: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: String

    var body: some View {
        List {
            option(Text("Not selected"), value: "")
            ForEach(Prefecture.allCases) { prefecture in
                option(Text(verbatim: prefecture.rawValue), value: prefecture.rawValue)
            }
        }
        .font(.b2Body)
        .scrollContentBackground(.hidden)
        .background(Color.paper)
        .tint(Color.brandPrimary)
        .navigationTitle(Text("Prefecture"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func option(_ label: Text, value: String) -> some View {
        let isSelected = selection == value
        return Button {
            selection = value
            dismiss()
        } label: {
            HStack {
                label
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .listRowBackground(Color.surface)
    }
}

#Preview {
    PostCreateView()
        .environment(MockDataRepository.preview)
}

#Preview("下書きの編集") {
    let repository = MockDataRepository.preview
    return NavigationStack {
        PostFormView(post: repository.drafts.first)
    }
    .environment(repository)
}

#Preview("公開済みの編集") {
    let repository = MockDataRepository.preview
    return NavigationStack {
        PostFormView(post: repository.myPosts.first)
    }
    .environment(repository)
}
