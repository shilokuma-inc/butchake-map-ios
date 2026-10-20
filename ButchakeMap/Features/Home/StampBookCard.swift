//
//  StampBookCard.swift
//  ButchakeMap
//

import SwiftUI

/// ホームの頭のスタンプ帳（台紙のカード。今月の自分の投稿 1 つ = スタンプ 1 こ。Discussion #77 の Q1）。
/// 今月の新しい 3 こまでを古い順に押し、その後ろに次の 1 こ分の空き欄（「？」）を置く。0 こなら台紙のイラストを出す。
/// 横に収まらないとき（大きめの文字・幅の狭い端末）は、見出しの下にスタンプを並べる。
/// VoiceOver ではカード全体を 1 つの要素として「スタンプ帳、今月 N こ」と読む
struct StampBookCard: View {
    let book: StampBook

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// スタンプの直径（モックの .rally-card の 52px）
    private static let stampSize: CGFloat = 52

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                stacked
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        caption
                            .fixedSize()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        stamps
                    }
                    stacked
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.kraft, in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.kraftBorder, lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Stamp book, \(book.count) this month"))
        .accessibilityIdentifier("home.stampBook")
    }

    /// 見出しの下にスタンプを並べる（収まらなければ横にスクロール）
    private var stacked: some View {
        VStack(alignment: .leading, spacing: 10) {
            caption
            ScrollView(.horizontal, showsIndicators: false) {
                stamps
            }
        }
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Stamp Book")
                .font(.b2Heading(size: 15, relativeTo: .subheadline))
                .foregroundStyle(Color.textPrimary)
            Text("This month: \(book.count)")
                .font(.b2Ticket(size: 13, relativeTo: .footnote))
                .foregroundStyle(Color.brandPrimary)
        }
    }

    @ViewBuilder private var stamps: some View {
        if book.stamps.isEmpty {
            // まだ 1 こも無い月は、最初の 1 こを押す欄が空いた台紙のイラスト
            Image(.emptyPosts)
                .resizable()
                .scaledToFit()
                .frame(width: 96)
                .accessibilityHidden(true)
        } else {
            HStack(spacing: 8) {
                ForEach(book.stamps) { stamp in
                    StampMark(top: stamp.date, main: stamp.place, size: Self.stampSize)
                }
                StampSlot(label: "？", size: Self.stampSize)
            }
        }
    }
}

#Preview("今月 2 こ") {
    StampBookCard(book: StampBook(count: 2, stamps: [
        .init(id: UUID(), date: "10.18", place: "金沢市"),
        .init(id: UUID(), date: "10.12", place: "横浜市")
    ]))
    .padding()
    .background(Color.paper)
}

#Preview("今月 0 こ") {
    StampBookCard(book: StampBook(count: 0, stamps: []))
        .padding()
        .background(Color.paper)
}

#Preview("大きな文字") {
    StampBookCard(book: StampBook(count: 5, stamps: [
        .init(id: UUID(), date: "10.18", place: "金沢市"),
        .init(id: UUID(), date: "10.12", place: "横浜市"),
        .init(id: UUID(), date: "10.3", place: "北海道")
    ]))
    .padding()
    .background(Color.paper)
    .environment(\.dynamicTypeSize, .accessibility5)
}
