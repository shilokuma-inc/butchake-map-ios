//
//  PostCreateView.swift
//  ButchakeMap
//

import SwiftUI

/// 投稿作成タブ
struct PostCreateView: View {
    var body: some View {
        FeaturePlaceholderView(tab: .create)
    }
}

#Preview {
    PostCreateView()
        .environment(MockDataRepository.preview)
}
