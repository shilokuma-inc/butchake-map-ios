//
//  ButchakeMap.swift
//  ButchakeMap
//
//  Created by 村石 拓海 on 2024/05/12.
//

import SwiftUI

@main
struct ButchakeMap: App {
    /// 全タブで共有する投稿のリポジトリ（メモリのみ）
    @State private var repository = MockDataRepository()

    init() {
        B2NavigationBarAppearance.apply()
    }

    var body: some Scene {
        WindowGroup {
            rootView
                // 書体を指定していない文字の既定（部品と画面の書体は、それぞれの View で当てる）
                .font(.b2Body)
                .environment(repository)
        }
    }

    /// 撮影モード（ScreenshotDemo）のときは、撮る画面を開く
    @ViewBuilder private var rootView: some View {
        switch ScreenshotDemo.scene {
        case .home, nil:
            MainTabView(initialTab: .home)
        }
    }
}
