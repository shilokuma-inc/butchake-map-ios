//
//  MainTabView.swift
//  ButchakeMap
//

import SwiftUI

/// アプリのルート。5 つのタブを並べる
struct MainTabView: View {
    @State private var selection: MainTab

    init(initialTab: MainTab = .home) {
        _selection = State(initialValue: initialTab)
    }

    var body: some View {
        TabView(selection: $selection) {
            ForEach(MainTab.allCases) { tab in
                content(for: tab)
                    .tabItem {
                        Label {
                            Text(tab.title)
                        } icon: {
                            Image(systemName: tab.symbolName)
                        }
                    }
                    .tag(tab)
            }
        }
    }

    @ViewBuilder
    private func content(for tab: MainTab) -> some View {
        switch tab {
        case .home:
            HomeView()
        case .map:
            PostMapView()
        case .create:
            PostCreateView()
        case .search:
            SearchView()
        case .myPage:
            MyPageView()
        }
    }
}

#Preview {
    MainTabView()
        .environment(MockDataRepository.preview)
}
