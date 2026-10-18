//
//  Badges.swift
//  ButchakeMap
//

import SwiftUI

/// アイコンと短い文言をカプセルで囲んだバッジ
struct TagBadge: View {
    let title: LocalizedStringResource
    let symbolName: String
    let color: Color

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: symbolName)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15), in: .capsule)
    }
}

/// 投稿のカテゴリのバッジ（アクセント色）
struct CategoryBadge: View {
    let category: Category

    var body: some View {
        TagBadge(title: category.displayName, symbolName: category.symbolName, color: .brandAccent)
    }
}

/// 投稿者の属性のバッジ（プライマリ色）
struct AuthorTypeBadge: View {
    let authorType: AuthorType

    var body: some View {
        TagBadge(title: authorType.displayName, symbolName: authorType.symbolName, color: .brandPrimary)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        ForEach(Category.allCases) { category in
            CategoryBadge(category: category)
        }
        ForEach(AuthorType.allCases) { authorType in
            AuthorTypeBadge(authorType: authorType)
        }
    }
    .padding()
}
