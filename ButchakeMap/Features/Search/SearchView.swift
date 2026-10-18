//
//  SearchView.swift
//  ButchakeMap
//

import SwiftUI

/// 検索タブ
struct SearchView: View {
    var body: some View {
        FeaturePlaceholderView(tab: .search)
    }
}

#Preview {
    SearchView()
        .environment(MockDataRepository.preview)
}
