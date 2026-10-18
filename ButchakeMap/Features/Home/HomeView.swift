//
//  HomeView.swift
//  ButchakeMap
//

import SwiftUI

/// ホームタブ（今週のぶっちゃけ・急上昇・フィード）
struct HomeView: View {
    var body: some View {
        FeaturePlaceholderView(tab: .home)
    }
}

#Preview {
    HomeView()
        .environment(MockDataRepository.preview)
}
