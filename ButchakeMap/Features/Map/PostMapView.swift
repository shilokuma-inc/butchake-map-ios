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
                // 選んだピンの投稿の 3 つの駅を、順位の順（1 → 2 → 3）に路線の緑でつなぐ。選んでいないときは引かない
                let route = viewModel.routeCoordinates(for: selectedPinID)
                if route.count > 1 {
                    MapPolyline(coordinates: route)
                        .stroke(
                            Color.brandAccent,
                            style: StrokeStyle(lineWidth: MapPinMetrics.routeLineWidth, lineCap: .round, lineJoin: .round)
                        )
                }
                ForEach(pins) { pin in
                    let isSelected = pin.id == selectedPinID
                    Annotation(pin.spotName, coordinate: pin.coordinate, anchor: .center) {
                        MapPinView(
                            pin: pin,
                            isSelected: isSelected,
                            neighbors: isSelected ? viewModel.neighbors(for: pin.id) : nil
                        )
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

/// 路線図の駅の丸と順位の番号のピン（モックの .map-pin）。選んだピンはインクの二重丸で大きくし（.map-pin.is-selected）、
/// 左に小さな駅名標（.pin-sign）を立てる
struct MapPinView: View {
    let pin: MapPin
    let isSelected: Bool
    /// 選んだピンの駅名標の帯に出す前後の駅。nil なら駅名標を出さない
    var neighbors: MapStationNeighbors?

    @ScaledMetric(relativeTo: MapPinMetrics.textStyle) private var scale: CGFloat = 1

    private var partScale: CGFloat {
        B2PartScale.clamped(scale, max: MapPinMetrics.maxScale)
    }

    private var diameter: CGFloat {
        (isSelected ? MapPinMetrics.selectedDiameter : MapPinMetrics.diameter) * partScale
    }

    /// 番号の基の大きさ（丸を大きくする上限を超えた分だけ下げる）
    private var fontSize: CGFloat {
        (isSelected ? MapPinMetrics.selectedFontSize : MapPinMetrics.fontSize)
            * B2PartScale.fontAdjustment(scale, max: MapPinMetrics.maxScale)
    }

    var body: some View {
        // 駅名標は丸の左に立てる。Annotation は中身の中心を座標に合わせるので、右にも同じ幅の見えない駅名標を置いて丸を中心に保つ
        // （丸の overlay で外に出すと、MapKit が中身の範囲の外の位置を正しく扱わず、駅名標が丸に重なるため）
        HStack(spacing: MapPinMetrics.signSpacing) {
            sign
            station
            sign
                .hidden()
        }
        .animation(.snappy, value: isSelected)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(pin.postTitle), Spot \(pin.order), \(pin.spotName)"))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    /// 駅の丸と番号
    private var station: some View {
        Text(verbatim: String(pin.order))
            .font(.b2Ticket(size: fontSize, relativeTo: MapPinMetrics.textStyle))
            .foregroundStyle(isSelected ? Color.brandPrimary : Color.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(MapPinMetrics.borderWidth * partScale + 1)
            .frame(width: diameter, height: diameter)
            .background(Color.surface, in: .circle)
            .overlay {
                rings
            }
    }

    /// 選んだピンの小さな駅名標（スポット名と、帯に前後の駅の番号）。読み上げはピンの文言に任せる
    @ViewBuilder private var sign: some View {
        if isSelected, let neighbors {
            MaxWidthLayout(maxWidth: MapPinMetrics.signMaxWidth) {
                StationSign(
                    name: Text(verbatim: pin.spotName),
                    previous: neighbors.previous.map { Text(verbatim: String($0)) },
                    next: neighbors.next.map { Text(verbatim: String($0)) },
                    nameFont: .b2Heading(size: 15, relativeTo: .subheadline),
                    nameTracking: 0.6
                )
            }
            // 地図の上で大きくなりすぎないよう、アクセシビリティの最初の大きさで止める（同じ名前はシートに大きく出る）
            .dynamicTypeSize(...MapPinMetrics.signMaxDynamicTypeSize)
            .transition(.opacity)
        }
    }

    /// 駅の丸の枠。選んでいないときは路線の緑の 4pt、選んだときはインクの二重丸（外 3pt・白のすき間 3pt・内 1.5pt）
    @ViewBuilder private var rings: some View {
        if isSelected {
            ZStack {
                Circle()
                    .strokeBorder(Color.brandPrimary, lineWidth: 3 * partScale)
                Circle()
                    .inset(by: 6 * partScale)
                    .strokeBorder(Color.brandPrimary, lineWidth: 1.5 * partScale)
            }
        } else {
            Circle()
                .strokeBorder(Color.brandAccent, lineWidth: MapPinMetrics.borderWidth * partScale)
        }
    }
}

/// マップのピンと路線の大きさの決まり（モックの theme.css の .map-pin と map.js の路線）
enum MapPinMetrics {
    /// 駅の丸の直径（選んでいないとき・選んだとき）
    static let diameter: CGFloat = 30
    static let selectedDiameter: CGFloat = 46
    /// 選んでいないときの路線の緑の枠
    static let borderWidth: CGFloat = 4
    /// 番号の大きさ（選んでいないとき・選んだとき）
    static let fontSize: CGFloat = 15
    static let selectedFontSize: CGFloat = 20
    /// 路線の線の太さ
    static let routeLineWidth: CGFloat = 9
    /// 駅名標の幅の上限（長いスポット名は折り返す）と、丸との間（モックの margin-left: -32px − 丸の半径 23px）
    static let signMaxWidth: CGFloat = 180
    static let signSpacing: CGFloat = 9
    /// 駅名標を大きくする文字の大きさの上限
    static let signMaxDynamicTypeSize = DynamicTypeSize.accessibility1
    /// 丸と番号を同じだけ大きくするための文字のスタイル
    static let textStyle: Font.TextStyle = .body
    /// 文字の大きさの設定で丸を大きくするのは 1.5 倍まで（近いピンどうしが重なりすぎないように）
    static let maxScale: CGFloat = 1.5
}

/// 中身を理想の幅で置き、上限を超えるときだけ上限の幅に収めて折り返させる
/// （`.fixedSize()` では 1 行のまま伸び、地図の Annotation では幅の提案が無く `.frame(maxWidth:)` が効かないため）
private struct MaxWidthLayout: Layout {
    let maxWidth: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let subview = subviews.first else {
            return .zero
        }
        return subview.sizeThatFits(fittingProposal(for: subview))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let subview = subviews.first else {
            return
        }
        subview.place(at: bounds.origin, proposal: fittingProposal(for: subview))
    }

    private func fittingProposal(for subview: LayoutSubview) -> ProposedViewSize {
        let idealWidth = subview.sizeThatFits(.unspecified).width
        return ProposedViewSize(width: min(idealWidth, maxWidth), height: nil)
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
