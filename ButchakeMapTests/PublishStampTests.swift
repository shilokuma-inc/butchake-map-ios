//
//  PublishStampTests.swift
//  ButchakeMapTests
//

@testable import ButchakeMap
import Foundation
import Testing

/// 公開したときに台紙へ押すスタンプ（3 こで 1 ページ。3 こそろったら success）と、押す動きの時間割り
@MainActor
struct PublishStampTests {
    private let me = "自分"
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        return calendar
    }()

    private func stamp(_ place: String, id: UUID = UUID()) -> StampBook.Stamp {
        StampBook.Stamp(id: id, date: "10.1", place: place)
    }

    private func publishedPost(city: String = "金沢市", createdAt: Date) -> Post {
        var post = Post.newDraft(authorName: me)
        post.prefecture = Prefecture.ishikawa.rawValue
        post.city = city
        post.createdAt = createdAt
        post.isDraft = false
        return post
    }

    /// 公開に必要な項目をすべて埋めた投稿
    private func filledPost(isDraft: Bool = true, createdAt: Date = Date()) -> Post {
        var post = Post.newDraft(authorName: me)
        post.title = "テストの三大"
        post.prefecture = Prefecture.ishikawa.rawValue
        post.city = "金沢市"
        for index in post.spots.indices {
            post.spots[index].name = "スポット\(index + 1)"
            post.spots[index].recommendation = "おすすめ\(index + 1)"
        }
        post.createdAt = createdAt
        post.isDraft = isDraft
        return post
    }

    // MARK: - 台紙のページ

    /// 今月の N こ目が、3 こで 1 ページの台紙のどこに入るか。3・6 こ目でそろう
    @Test(arguments: [
        (count: 1, earlier: 0, isComplete: false),
        (count: 2, earlier: 1, isComplete: false),
        (count: 3, earlier: 2, isComplete: true),
        (count: 4, earlier: 0, isComplete: false),
        (count: 5, earlier: 1, isComplete: false),
        (count: 6, earlier: 2, isComplete: true)
    ])
    func pageOfStampBook(count: Int, earlier: Int, isComplete: Bool) throws {
        let createdAt = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 18, hour: 12)))
        let post = publishedPost(createdAt: createdAt)
        // ホームのスタンプ帳は今月の新しい 3 こを古い順に持ち、公開したばかりの投稿が最後に来る
        let others = (0..<min(count, StampBook.visibleStampLimit) - 1).map { stamp("前\($0)") }
        let book = StampBook(count: count, stamps: others + [stamp("金沢市", id: post.id)])

        let result = try #require(PublishStamp.make(book: book, published: post, calendar: calendar))

        #expect(result.earlier.map(\.place) == Array(others.map(\.place).suffix(earlier)))
        #expect(result.filledCount == earlier + 1)
        #expect(result.emptySlotCount == PublishStamp.slotCount - earlier - 1)
        #expect(result.isComplete == isComplete)
        #expect(result.date == "10.18")
        #expect(result.place == "金沢市")
        // 見出しは「今月 N こ」（分母を出さない）
        #expect(result.monthCount == count)
    }

    /// 今月のスタンプに入っていない投稿（先月以前の公開など）では押さない
    @Test
    func noStampForPostOutsideThisMonth() {
        let post = publishedPost(createdAt: Date(timeIntervalSince1970: 0))
        #expect(PublishStamp.make(book: StampBook(count: 1, stamps: [stamp("札幌市")]), published: post) == nil)
        #expect(PublishStamp.make(book: StampBook(count: 0, stamps: []), published: post) == nil)
    }

    /// 市区町村が空なら都道府県をスタンプの下に入れる（詳細の駅のスタンプと同じ）
    @Test
    func placeFallsBackToPrefecture() throws {
        let post = publishedPost(city: "", createdAt: Date())
        let result = try #require(PublishStamp.make(book: StampBook(count: 1, stamps: [stamp("", id: post.id)]), published: post))
        #expect(result.place == Prefecture.ishikawa.rawValue)
    }

    // MARK: - 動きの時間割り

    /// 全体 1.0 秒。0.2 秒で押し、0.08 秒止まり、0.6 秒で上がりきる。「公開しました」は 0.6〜0.8 秒で出す
    @Test
    func timelineMatchesMotionSpec() {
        #expect(PublishStampTimeline.duration == 1.0)
        #expect(PublishStampTimeline.pressTime == 0.2)
        #expect(abs(PublishStampTimeline.holdEndTime - PublishStampTimeline.pressTime - 0.08) < 0.000_1)
        #expect(PublishStampTimeline.liftEndTime <= PublishStampTimeline.duration)
        #expect(PublishStampTimeline.messageEndTime <= PublishStampTimeline.duration)
        #expect(PublishStampTimeline.inkStartScale == 1.1)
    }

    /// スタンプ台は上から easeIn で下りて 0.2 秒で押し、止まったあと easeOut で上がりながら消える
    @Test
    func stamperDropsPressesAndLifts() {
        let start = PublishStampTimeline.frame(at: 0, reduceMotion: false)
        #expect(start.stamperLift == 1)
        #expect(start.stamperOpacity == 1)
        #expect(start.inkOpacity == 0)
        #expect(!start.isStamped)

        // easeIn なので、半分の時刻ではまだ半分より上にいる
        let falling = PublishStampTimeline.frame(at: 0.1, reduceMotion: false)
        #expect(falling.stamperLift > 0.5 && falling.stamperLift < 1)
        #expect(falling.inkOpacity == 0)

        for time in [0.2, 0.24, 0.279] {
            let pressing = PublishStampTimeline.frame(at: time, reduceMotion: false)
            #expect(pressing.stamperLift == 0, "\(time) 秒")
            #expect(pressing.stamperOpacity == 1, "\(time) 秒")
        }

        let lifting = PublishStampTimeline.frame(at: 0.4, reduceMotion: false)
        #expect(lifting.stamperLift > 0 && lifting.stamperLift < 1)
        #expect(lifting.stamperOpacity > 0 && lifting.stamperOpacity < 1)

        let lifted = PublishStampTimeline.frame(at: 0.6, reduceMotion: false)
        #expect(lifted.stamperLift == 1)
        #expect(lifted.stamperOpacity == 0)
    }

    /// インクの丸は押した瞬間に 1.1 倍で出て、1.0 倍ににじんで収まる。「公開しました」はそのあとに出す
    @Test
    func inkSpreadsAndMessageFollows() {
        let pressed = PublishStampTimeline.frame(at: 0.2, reduceMotion: false)
        #expect(pressed.isStamped)
        #expect(pressed.inkOpacity == 1)
        #expect(abs(pressed.inkScale - 1.1) < 0.000_1)
        #expect(pressed.messageOpacity == 0)

        let settling = PublishStampTimeline.frame(at: 0.4, reduceMotion: false)
        #expect(settling.inkScale > 1 && settling.inkScale < 1.1)

        let settled = PublishStampTimeline.frame(at: 0.6, reduceMotion: false)
        #expect(abs(settled.inkScale - 1) < 0.000_1)
        #expect(settled.messageOpacity == 0)

        let end = PublishStampTimeline.frame(at: 1.0, reduceMotion: false)
        #expect(end.messageOpacity == 1)
        #expect(end.inkOpacity == 1)
        #expect(abs(end.inkScale - 1) < 0.000_1)
    }

    /// 範囲の外の時刻は、始まりと終わりの見た目にする
    @Test
    func clampsOutOfRangeTime() {
        #expect(PublishStampTimeline.frame(at: -1, reduceMotion: false) == PublishStampTimeline.frame(at: 0, reduceMotion: false))
        #expect(PublishStampTimeline.frame(at: 5, reduceMotion: false) == PublishStampTimeline.frame(at: 1, reduceMotion: false))
    }

    /// Reduce Motion のときはスタンプ台を出さず、インクの丸と「公開しました」を 0.2 秒でフェードインする（大きさは変えない）
    @Test
    func reduceMotionFadesInWithoutStamper() {
        for time in [0, 0.1, 0.2, 1.0] {
            let frame = PublishStampTimeline.frame(at: time, reduceMotion: true)
            #expect(frame.stamperOpacity == 0, "\(time) 秒")
            #expect(frame.inkScale == 1, "\(time) 秒")
            #expect(frame.inkOpacity == frame.messageOpacity, "\(time) 秒")
        }
        #expect(PublishStampTimeline.frame(at: 0, reduceMotion: true).inkOpacity == 0)
        let halfway = PublishStampTimeline.frame(at: 0.1, reduceMotion: true).inkOpacity
        #expect(halfway > 0 && halfway < 1)
        #expect(PublishStampTimeline.frame(at: 0.2, reduceMotion: true).inkOpacity == 1)
    }

    /// 押した瞬間（0.2 秒）に impact、そろったら終わり（1.0 秒）に success、そろわなければ success は鳴らさない
    @Test
    func eventsFireHapticsAndFinish() {
        let complete = PublishStampTimeline.events(reduceMotion: false, isComplete: true)
        #expect(complete.map(\.event) == [.press, .complete, .finish])
        #expect(complete.map(\.time) == [0.2, 1.0, 1.0])

        let incomplete = PublishStampTimeline.events(reduceMotion: false, isComplete: false)
        #expect(incomplete.map(\.event) == [.press, .finish])
        #expect(incomplete.map(\.time) == [0.2, 1.0])
    }

    /// Reduce Motion のときは、インクを出し始めたときに impact、出しきったとき（0.2 秒）にそろえば success。終わりは同じ 1.0 秒
    @Test
    func reduceMotionEvents() {
        let complete = PublishStampTimeline.events(reduceMotion: true, isComplete: true)
        #expect(complete.map(\.event) == [.press, .complete, .finish])
        #expect(complete.map(\.time) == [0, 0.2, 1.0])
        #expect(PublishStampTimeline.events(reduceMotion: true, isComplete: false).map(\.event) == [.press, .finish])
    }

    // MARK: - 公開のフォーム

    /// 新しく公開したら、スタンプを押し終えるまで結果のアラートを出さない。閉じたらスタンプも片付ける
    @Test
    func newPublicationPressesStampBeforeAlert() throws {
        let repository = MockDataRepository(posts: [], currentUserName: me)
        let viewModel = PostCreateViewModel(post: nil, repository: repository)
        viewModel.post = filledPost()

        viewModel.publish()

        let stamp = try #require(viewModel.publishStamp)
        #expect(stamp.earlier.isEmpty)
        #expect(!stamp.isComplete)
        #expect(viewModel.isPressingStamp)
        #expect(viewModel.outcome == .published)
        #expect(!viewModel.showsOutcomeAlert)

        viewModel.finishPressingStamp()
        #expect(viewModel.showsOutcomeAlert)

        #expect(viewModel.dismissOutcome() == .published)
        #expect(viewModel.publishStamp == nil)
        #expect(viewModel.outcome == nil)
        #expect(!viewModel.showsOutcomeAlert)
    }

    /// 今月 3 こ目の公開（下書きの公開も同じ）でページがそろう
    @Test
    func thirdPublicationThisMonthCompletesPage() throws {
        let draft = filledPost()
        let repository = MockDataRepository(
            posts: [filledPost(isDraft: false), filledPost(isDraft: false), draft],
            currentUserName: me
        )
        let viewModel = PostCreateViewModel(post: draft, repository: repository)

        viewModel.publish()

        let stamp = try #require(viewModel.publishStamp)
        #expect(stamp.earlier.count == 2)
        #expect(stamp.isComplete)
    }

    /// 公開済みの投稿の編集は新しいスタンプにならないので、今までどおりすぐに結果のアラートを出す
    @Test
    func editingPublishedPostShowsAlertWithoutStamp() {
        let published = filledPost(isDraft: false)
        let repository = MockDataRepository(posts: [published], currentUserName: me)
        let viewModel = PostCreateViewModel(post: published, repository: repository)

        viewModel.publish()

        #expect(viewModel.outcome == .published)
        #expect(viewModel.publishStamp == nil)
        #expect(viewModel.showsOutcomeAlert)
    }

    /// 公開できなかったときはスタンプを押さない
    @Test
    func failedPublicationShowsAlertWithoutStamp() {
        let draft = filledPost()
        let repository = MockDataRepository(posts: [draft], currentUserName: me)
        let viewModel = PostCreateViewModel(post: draft, repository: repository)
        repository.delete(postID: draft.id)

        viewModel.publish()

        #expect(viewModel.outcome == .failed(.notFound))
        #expect(viewModel.publishStamp == nil)
        #expect(viewModel.showsOutcomeAlert)
    }
}
