//
//  Badges.swift
//  ButchakeMap
//

import SwiftUI

/// アイコンと短い文言をカプセルで囲んだバッジ（B-2: 白の地に色の枠と文字、または色の地に白の文字）
struct TagBadge: View {
    enum Style {
        /// 白の地に、色の枠と文字（カテゴリ）
        case outlined
        /// 色の地に、白の文字（投稿者の属性）
        case filled
    }

    let title: LocalizedStringResource
    let symbolName: String
    let color: Color
    var style: Style = .outlined

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: symbolName)
        }
        .font(.b2Heading(size: 13, relativeTo: .footnote))
        .foregroundStyle(style == .filled ? Color.surface : color)
        .padding(.horizontal, 10)
        .padding(.vertical, 3)
        .background(style == .filled ? color : Color.surface, in: .capsule)
        .overlay {
            Capsule()
                .strokeBorder(color, lineWidth: 1.5)
        }
    }
}

/// 投稿のカテゴリのバッジ（路線の緑の枠と文字）
struct CategoryBadge: View {
    let category: Category

    var body: some View {
        TagBadge(title: category.displayName, symbolName: category.symbolName, color: .brandAccent)
    }
}

/// 投稿者の属性のバッジ（インクの地に白の文字）
struct AuthorTypeBadge: View {
    let authorType: AuthorType

    var body: some View {
        TagBadge(title: authorType.displayName, symbolName: authorType.symbolName, color: .brandPrimary, style: .filled)
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
    .background(Color.paper)
}

#Preview("大きな文字") {
    VStack(alignment: .leading, spacing: 12) {
        CategoryBadge(category: .gourmet)
        AuthorTypeBadge(authorType: .local)
    }
    .padding()
    .background(Color.paper)
    .environment(\.dynamicTypeSize, .accessibility5)
}
