//
//  PostMapView.swift
//  ButchakeMap
//

import MapKit
import SwiftUI

/// マップタブ（スポットごとの番号付きピン。タップでハーフシート、そこから投稿詳細へ）
struct PostMapView: View {
    @Environment(MockDataRepository.self) private var repository
    @State private var path: [PostDestination] = []
    @State private var selectedPinID: MapPinID?
    /// シートを閉じ終えてから push する投稿詳細
    @State private var pendingDestination: PostDestination?

    private var viewModel: PostMapViewModel {
        PostMapViewModel(repository: repository)
    }

    var body: some View {
        let pins = viewModel.pins
        NavigationStack(path: $path) {
            Map(initialPosition: .region(viewModel.initialRegion), selection: $selectedPinID) {
                ForEach(pins) { pin in
                    Annotation(pin.spotName, coordinate: pin.coordinate, anchor: .center) {
                        MapPinView(pin: pin, isSelected: pin.id == selectedPinID)
                    }
                    // 近いスポットの名前が重なって読めなくなるため、名前は地図に出さずシートに出す
                    .annotationTitles(.hidden)
                    .tag(pin.id)
                }
            }
            .navigationTitle(Text("Map"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .postDetailDestination()
            .sheet(item: $selectedPinID, onDismiss: pushPendingDestination) { pinID in
                MapPinSheet(pinID: pinID, onOpenDetail: openDetail)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            // 削除・下書きへの変更などでピンが消えたら、開いているシートも閉じる
            .onChange(of: pins.map(\.id)) { _, pinIDs in
                if let selectedPinID, !pinIDs.contains(selectedPinID) {
                    self.selectedPinID = nil
                }
            }
        }
    }

    /// シートを閉じ、閉じ終えたら投稿詳細を push する
    private func openDetail(postID: Post.ID) {
        pendingDestination = PostDestination(postID: postID)
        selectedPinID = nil
    }

    private func pushPendingDestination() {
        guard let pendingDestination else {
            return
        }
        path.append(pendingDestination)
        self.pendingDestination = nil
    }
}

/// スポットの番号（①②③）を出すピン
struct MapPinView: View {
    let pin: MapPin
    let isSelected: Bool

    var body: some View {
        Image(systemName: "\(pin.order).circle.fill")
            .font(isSelected ? .largeTitle : .title)
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, isSelected ? Color.brandAccent : Color.brandPrimary)
            .background(.white, in: .circle)
            .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
            .animation(.snappy, value: isSelected)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(pin.postTitle), Spot \(pin.order), \(pin.spotName)"))
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// ピンをタップしたときのハーフシート。どの投稿の何番目のスポットかを出す
struct MapPinSheet: View {
    @Environment(MockDataRepository.self) private var repository
    let pinID: MapPinID
    let onOpenDetail: (Post.ID) -> Void

    private var viewModel: PostMapViewModel {
        PostMapViewModel(repository: repository)
    }

    var body: some View {
        if let post = viewModel.post(for: pinID), let spot = viewModel.spot(for: pinID) {
            content(post: post, spot: spot)
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
        }
    }

    private func content(post: Post, spot: Spot) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    CategoryBadge(category: post.category)
                    Text(post.title)
                        .font(.title3.bold())
                        .accessibilityAddTraits(.isHeader)
                    Label(post.area, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                spotCard(spot: spot)
                HStack(spacing: 16) {
                    LikeButton(post: post) { viewModel.toggleLike(postID: post.id) }
                    StarButton(post: post) { viewModel.toggleStar(postID: post.id) }
                    Spacer(minLength: 0)
                    Button("View Post", systemImage: "chevron.right") {
                        onOpenDetail(post.id)
                    }
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.borderedProminent)
                    .tint(Color.brandPrimary)
                }
            }
            .padding()
        }
        .background(Color.paper)
    }

    private func spotCard(spot: Spot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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
        }
        .cardStyle()
    }
}

#Preview {
    PostMapView()
        .environment(MockDataRepository.preview)
}

#Preview("投稿なし") {
    PostMapView()
        .environment(MockDataRepository(posts: []))
}

#Preview("ハーフシート") {
    let repository = MockDataRepository.preview
    let pin = PostMapViewModel(repository: repository).pins[1]
    return MapPinSheet(pinID: pin.id) { _ in }
        .environment(repository)
}

#Preview("削除済みのシート") {
    MapPinSheet(pinID: MapPinID(postID: UUID(), spotID: UUID())) { _ in }
        .environment(MockDataRepository.preview)
}
