//
//  MyPageView.swift
//  ButchakeMap
//

import SwiftUI

/// マイページタブ
struct MyPageView: View {
    var body: some View {
        FeaturePlaceholderView(tab: .myPage)
    }
}

#Preview {
    MyPageView()
        .environment(MockDataRepository.preview)
}
