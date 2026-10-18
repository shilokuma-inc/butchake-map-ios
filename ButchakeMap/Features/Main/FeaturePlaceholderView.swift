//
//  FeaturePlaceholderView.swift
//  ButchakeMap
//
//  画面を実装するまでタブに出す仮の表示
//

import SwiftUI

struct FeaturePlaceholderView: View {
    let tab: MainTab

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label {
                    Text(tab.title)
                } icon: {
                    Image(systemName: tab.symbolName)
                }
            } description: {
                Text("This screen is under construction.")
            }
            .navigationTitle(Text(tab.title))
        }
    }
}

#Preview {
    FeaturePlaceholderView(tab: .home)
}
