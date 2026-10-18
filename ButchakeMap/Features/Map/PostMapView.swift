//
//  PostMapView.swift
//  ButchakeMap
//

import SwiftUI

/// マップタブ（スポットのピン）
struct PostMapView: View {
    var body: some View {
        FeaturePlaceholderView(tab: .map)
    }
}

#Preview {
    PostMapView()
        .environment(MockDataRepository.preview)
}
