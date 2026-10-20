//
//  StationSign.swift
//  ButchakeMap
//

import SwiftUI

/// B-2 の駅名標（白の地に駅名と英字、下の緑の帯に前後の見出し「◀ … ／ … ▶」）。見出し・都市の名前・地図の駅に使う
///
/// 駅名は大きな文字で 2 行以上に折り返す。帯の前後の見出しは、アクセシビリティの大きな文字では横に並べず縦に積む。
/// 英字と帯は飾りなので読み上げず、駅名だけを読む（見出しにするかは isHeader）
struct StationSign: View {
    let name: Text
    var english: Text?
    var previous: Text?
    var next: Text?
    var nameFont: Font = .b2Heading(size: 19, relativeTo: .title3)
    /// 駅名の字間（モックの letter-spacing: .12em）
    var nameTracking: CGFloat = 2.3
    var isHeader = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 0) {
            name
                .font(nameFont)
                .tracking(nameTracking)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.top, 4)
                .padding(.bottom, english == nil ? 4 : 0)
                .accessibilityAddTraits(isHeader ? .isHeader : [])
            if let english {
                english
                    .font(.b2Ticket(size: 13, relativeTo: .footnote))
                    .tracking(2.6)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
                    .accessibilityHidden(true)
            }
            if previous != nil || next != nil {
                bar
                    .accessibilityHidden(true)
            }
        }
        .background(Color.surface)
        .clipShape(.rect(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.textPrimary, lineWidth: 2)
        }
    }

    /// 緑の帯。前の見出しは左、次の見出しは右に寄せる
    private var bar: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(spacing: 8))
        return layout {
            if let previous {
                HStack(spacing: 4) {
                    Text(verbatim: "◀")
                    previous
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let next {
                HStack(spacing: 4) {
                    next
                    Text(verbatim: "▶")
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .font(.b2Heading(size: 13, relativeTo: .footnote))
        .foregroundStyle(Color.surface)
        .padding(.horizontal, 10)
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity)
        .background(Color.brandAccent)
    }
}

#Preview("駅名標") {
    VStack(spacing: 16) {
        StationSign(
            name: Text(verbatim: "今週のぶっちゃけ"),
            english: Text(verbatim: "THIS WEEK"),
            next: Text(verbatim: "急上昇"),
            isHeader: true
        )
        StationSign(
            name: Text(verbatim: "急上昇"),
            english: Text(verbatim: "TRENDING"),
            previous: Text(verbatim: "今週のぶっちゃけ"),
            next: Text(verbatim: "新着の投稿")
        )
        StationSign(
            name: Text(verbatim: "金沢市"),
            english: Text(verbatim: "ISHIKAWA"),
            previous: Text(verbatim: "グルメ"),
            next: Text(verbatim: "地元民"),
            nameFont: .b2Heading(size: 30, relativeTo: .largeTitle)
        )
    }
    .padding()
    .background(Color.paper)
}

#Preview("駅名標（大きな文字）") {
    StationSign(
        name: Text(verbatim: "今週のぶっちゃけ"),
        english: Text(verbatim: "THIS WEEK"),
        previous: Text(verbatim: "新着の投稿"),
        next: Text(verbatim: "急上昇")
    )
    .padding()
    .background(Color.paper)
    .environment(\.dynamicTypeSize, .accessibility5)
}
