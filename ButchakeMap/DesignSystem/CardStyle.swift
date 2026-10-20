//
//  CardStyle.swift
//  ButchakeMap
//

import SwiftUI

/// 投稿カードなどに使う角丸の背景（B-2 の白の地・枠・下に 1pt の枠の色の影）
struct CardStyle: ViewModifier {
    private static let cornerRadius: CGFloat = 6

    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.surface, in: .rect(cornerRadius: Self.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: Self.cornerRadius)
                    .strokeBorder(Color.cardBorder, lineWidth: 1)
            }
            .shadow(color: .cardBorder, radius: 0, y: 1)
    }
}

extension View {
    /// カードの見た目（余白・角丸の背景・枠・影）を付ける
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
    .background(Color.paper)
}
