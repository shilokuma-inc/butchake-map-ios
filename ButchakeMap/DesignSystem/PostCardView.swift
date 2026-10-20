//
//  PostCardView.swift
//  ButchakeMap
//

import SwiftUI

/// フィード・検索・マイページに並べる投稿カード（B-2: スタンプラリーの台紙。3 つのスポットと、投稿日のスタンプ）
struct PostCardView: View {
    let post: Post
    let onLike: () -> Void
    let onStar: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                PostThumbnail(post: post)
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.title)
                        .font(.b2Heading(size: 17, relativeTo: .headline))
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text(post.area)
                        .font(.b2Text(size: 15, relativeTo: .subheadline))
                        .foregroundStyle(Color.textSecondary)
                }
                // 題名は省略せず折り返す（横の並びの中で 1 行に縮められないように）
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            stackedLayout(spacing: 8) {
                CategoryBadge(category: post.category)
                AuthorTypeBadge(authorType: post.authorType)
            }
            stackedLayout(spacing: 10) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(post.spots) { spot in
                        SpotNameRow(spot: spot)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                // 台紙に押した投稿日のスタンプ（上は年、真ん中は「M.d」、下は市区町村）。飾りなので読み上げない
                StampMark(
                    top: Self.stampYear(of: post),
                    main: PostDetailViewModel.stampDate(of: post),
                    bottom: PostDetailViewModel.stampPlace(of: post)
                )
            }
            HStack(spacing: 16) {
                Text(post.authorName)
                    .font(.b2Text(size: 13, relativeTo: .footnote))
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                LikeButton(post: post, action: onLike)
                StarButton(post: post, action: onStar)
            }
        }
        .cardStyle()
    }

    /// 投稿日の年（スタンプの上の小さな文字。端末のカレンダー）
    static func stampYear(of post: Post, calendar: Calendar = .current) -> String {
        String(calendar.component(.year, from: post.createdAt))
    }

    /// 通常は横に、アクセシビリティの大きな文字では縦（左寄せ）に並べる
    private func stackedLayout<Content: View>(spacing: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: spacing))
            : AnyLayout(HStackLayout(spacing: spacing))
        return layout(content)
    }
}

/// 番号付きのスポット名の 1 行（路線図の駅の番号の丸と名前）
struct SpotNameRow: View {
    let spot: Spot

    var body: some View {
        HStack(spacing: 8) {
            RouteRankBadge(number: spot.order, style: .compact)
            Text(spot.name)
                .font(.b2Text(size: 15, relativeTo: .subheadline))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
        }
    }
}

/// 投稿カードのサムネイル。スポットの写真があれば 1 枚目を、無ければカテゴリのアイコンを出す（B-2: インクの枠の丸）
struct PostThumbnail: View {
    let post: Post
    var size: CGFloat = 56

    var body: some View {
        if let photoData = post.coverPhotoData {
            SpotPhotoImage(data: photoData)
                .frame(width: size, height: size)
                .clipShape(.circle)
                .overlay {
                    Circle()
                        .strokeBorder(Color.brandPrimary, lineWidth: 2)
                }
        } else {
            CategoryThumbnail(category: post.category, size: size)
        }
    }
}

/// 写真の代わりに出すカテゴリのアイコン（台紙の地にインクのアイコンと枠の丸）
struct CategoryThumbnail: View {
    let category: Category
    var size: CGFloat = 56

    var body: some View {
        Image(systemName: category.symbolName)
            .font(.system(size: size * 0.42))
            .foregroundStyle(Color.brandPrimary)
            .frame(width: size, height: size)
            .background(Color.kraft, in: .circle)
            .overlay {
                Circle()
                    .strokeBorder(Color.brandPrimary, lineWidth: 2)
            }
            .accessibilityHidden(true)
    }
}

/// いいねの切り替えボタン（件数つき）。件数は発車標の札で出し、変わる桁だけパタパタ回す（B-2 の動き。モックの motion.html）。
/// 視差効果を減らす設定では札を回さず、ハートの塗りと件数をクロスフェードする
struct LikeButton: View {
    let post: Post
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 札の桁ごとの前後の数字（件数が変わるたびに、前の件数から新しい件数へ入れ替える）
    @State private var flapSlots: [DepartureBoardFlapSlot]
    /// 札の前後の数字と、押したあとの変化か
    @State private var turn: LikeFlapTurn
    /// 札を回し始めるたびに増やす（KeyframeAnimator のきっかけ）
    @State private var turnCount = 0
    /// 押したあとの変化で、札が止まるたびに増やす（selection のハプティクスのきっかけ）
    @State private var settledCount = 0
    /// 止まったときにハプティクスを鳴らすための待ち（続けて押したら取り消して、最後の 1 回だけ鳴らす）
    @State private var hapticTask: Task<Void, Never>?

    init(post: Post, action: @escaping () -> Void) {
        self.post = post
        self.action = action
        _flapSlots = State(initialValue: DepartureBoardFlap.slots(from: post.likeCount, to: post.likeCount))
        _turn = State(initialValue: LikeFlapTurn(count: post.likeCount))
    }

    var body: some View {
        Button {
            turn.tapped()
            action()
        } label: {
            LikeButtonLabel(
                heartFill: post.isLiked ? 1 : 0,
                heartAnimation: reduceMotion
                    ? .easeInOut(duration: DepartureBoardFlap.crossfadeDuration)
                    : .easeOut(duration: DepartureBoardFlap.heartFillDuration)
            ) {
                count
            }
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(Text("Like"))
        .accessibilityValue(Text(post.likeCount, format: .number))
        .accessibilityAddTraits(post.isLiked ? .isSelected : [])
        .onChange(of: LikeCountKey(postID: post.id, count: post.likeCount)) { oldKey, newKey in
            guard oldKey.postID == newKey.postID else {
                // 別の投稿に変わったときは回さずに入れ替える
                turn.reset(count: newKey.count)
                flapSlots = DepartureBoardFlap.slots(from: newKey.count, to: newKey.count)
                return
            }
            let isTapped = turn.countChanged(to: newKey.count, at: Date())
            flapSlots = DepartureBoardFlap.slots(from: turn.from, to: turn.to)
            turnCount &+= 1
            // 押していない変化（ほかの画面で押した・同期など）では鳴らさない。続けて押したら最後の 1 回だけ鳴らす
            hapticTask?.cancel()
            hapticTask = nil
            guard isTapped else {
                return
            }
            let duration = reduceMotion ? DepartureBoardFlap.crossfadeDuration : DepartureBoardFlap.totalDuration
            hapticTask = Task {
                try? await Task.sleep(for: .seconds(duration))
                guard !Task.isCancelled else {
                    return
                }
                settledCount &+= 1
            }
        }
        .onDisappear {
            hapticTask?.cancel()
            hapticTask = nil
        }
        .sensoryFeedback(.selection, trigger: settledCount)
    }

    @ViewBuilder private var count: some View {
        if reduceMotion {
            // 札を回さず、件数を入れ替えてクロスフェードする
            ZStack {
                DepartureBoardFlapCount(value: post.likeCount)
                    .id(post.likeCount)
                    .transition(.opacity)
            }
            .animation(.easeInOut(duration: DepartureBoardFlap.crossfadeDuration), value: post.likeCount)
        } else {
            KeyframeAnimator(initialValue: 1.0, trigger: turnCount) { progress in
                DepartureBoardFlapCount(slots: flapSlots, progress: progress)
            } keyframes: { _ in
                // ハートを塗る間は止めておき、塗り終えたら 2 段（上半分・下半分）を通しで回す（段ごとの easeIn は札の側で掛ける）
                MoveKeyframe(0.0)
                LinearKeyframe(0.0, duration: DepartureBoardFlap.heartFillDuration)
                LinearKeyframe(1.0, duration: DepartureBoardFlap.turnDuration)
            }
        }
    }

    /// 件数の変わり目を、同じ投稿の中の変化か、別の投稿への入れ替えかで分けるための値
    private struct LikeCountKey: Equatable {
        let postID: Post.ID
        let count: Int
    }
}

/// いいねのボタンの中身（ハートと件数）。ハートは枠と塗りを重ね、塗りの進み具合（0〜1）で入れ替える。
/// Preview・画像の書き出しで、動きの途中の見た目を進み具合を渡して描けるよう分けている
struct LikeButtonLabel<Count: View>: View {
    /// ハートの塗りの進み具合（0 は枠だけ、1 は塗り）
    let heartFill: Double
    /// 塗りを変えるときの動き（nil なら動かさない）
    var heartAnimation: Animation?
    @ViewBuilder let count: Count

    var body: some View {
        Label {
            count
        } icon: {
            ZStack {
                Image(systemName: "heart")
                    .foregroundStyle(Color.textPrimary)
                    .opacity(1 - heartFill)
                Image(systemName: "heart.fill")
                    .foregroundStyle(Color.brandPrimary)
                    .opacity(heartFill)
            }
            .animation(heartAnimation, value: heartFill)
        }
        .font(.b2Heading(size: 15, relativeTo: .subheadline))
    }
}

/// スター（保存）の切り替えボタン（件数つき）
struct StarButton: View {
    let post: Post
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text(post.starCount, format: .number)
            } icon: {
                Image(systemName: post.isStarred ? "star.fill" : "star")
            }
            .font(.b2Heading(size: 15, relativeTo: .subheadline))
            .foregroundStyle(post.isStarred ? Color.brandPrimary : Color.textPrimary)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(Text("Save"))
        .accessibilityValue(Text(post.starCount, format: .number))
        .accessibilityAddTraits(post.isStarred ? .isSelected : [])
    }
}

/// カードを NavigationLink で包むと、VoiceOver ではカード全体が 1 つのリンクになり中のボタンに個別に届かない。
/// そのため、いいね・スターをリンクのカスタムアクション（ローターの「アクション」）としても出す
struct PostCardAccessibilityActions: ViewModifier {
    let post: Post
    /// nil ならいいねのアクションを出さない（いいねボタンの無いカード用）
    let onLike: (() -> Void)?
    let onStar: () -> Void

    func body(content: Content) -> some View {
        if let onLike {
            content
                .accessibilityAction(named: post.isLiked ? Text("Remove Like") : Text("Like"), onLike)
                .accessibilityAction(named: post.isStarred ? Text("Remove from Saved") : Text("Save"), onStar)
        } else {
            content
                .accessibilityAction(named: post.isStarred ? Text("Remove from Saved") : Text("Save"), onStar)
        }
    }
}

extension View {
    /// NavigationLink で包んだ投稿カードに、いいね・スターの VoiceOver のアクションを付ける（リンクの外側に付ける）
    func postCardAccessibilityActions(post: Post, onLike: (() -> Void)? = nil, onStar: @escaping () -> Void) -> some View {
        modifier(PostCardAccessibilityActions(post: post, onLike: onLike, onStar: onStar))
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(MockData.posts().filter { !$0.isDraft }) { post in
                PostCardView(post: post, onLike: {}, onStar: {})
            }
        }
        .padding()
    }
    .background(Color.paper)
    .environment(MockDataRepository.preview)
}
