//
//  CardStyle.swift
//  ButchakeMap
//

import SwiftUI

/// 投稿カードなどに使う角丸の背景
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
    }
}

extension View {
    /// カードの見た目（余白・角丸の背景・影）を付ける
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

#Preview {
    VStack(spacing: 16) {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: "金沢市民が本気で教える三大回転寿司")
                .font(.headline)
            HStack {
                CategoryBadge(category: .gourmet)
                AuthorTypeBadge(authorType: .local)
            }
        }
        .cardStyle()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
