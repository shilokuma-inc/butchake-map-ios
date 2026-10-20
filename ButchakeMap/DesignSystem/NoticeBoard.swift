//
//  NoticeBoard.swift
//  ButchakeMap
//

import SwiftUI

/// B-2 の駅の掲示板（文字色の地に白の文字の札と、その下の本文）。ぶっちゃけコメントに使う
///
/// 札と本文はまとめて 1 つの要素として読む（「ぶっちゃけコメント、本文」）
struct NoticeBoard: View {
    let label: Text
    let text: Text

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "mappin")
                    .accessibilityHidden(true)
                label
                    .tracking(1)
            }
            .font(.b2Ticket(size: 13, relativeTo: .footnote))
            .foregroundStyle(Color.surface)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.textPrimary)
            text
                .font(.b2Text(size: 16, relativeTo: .callout))
                .lineSpacing(6)
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
        }
        .background(Color.surface)
        .clipShape(.rect(cornerRadius: 4))
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.textPrimary, lineWidth: 2)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("掲示板の札") {
    NoticeBoard(
        label: Text("Honest Comment"),
        text: Text(verbatim: "ランチのコスパと鮮度は県内トップクラス。平日の開店直後なら待たずに入れる。")
    )
    .padding()
    .background(Color.paper)
}

#Preview("掲示板の札（大きな文字）") {
    NoticeBoard(
        label: Text("Honest Comment"),
        text: Text(verbatim: "白えびとガスエビは絶対に頼んで。")
    )
    .padding()
    .background(Color.paper)
    .environment(\.dynamicTypeSize, .accessibility5)
}
