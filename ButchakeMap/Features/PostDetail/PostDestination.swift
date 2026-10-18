//
//  PostDestination.swift
//  ButchakeMap
//

import SwiftUI

/// 投稿詳細への遷移先。投稿そのものではなく ID を渡し、詳細は Repository から引く
struct PostDestination: Hashable {
    let postID: Post.ID
}

extension View {
    /// NavigationStack の中で PostDestination を投稿詳細に結び付ける
    func postDetailDestination() -> some View {
        navigationDestination(for: PostDestination.self) { destination in
            PostDetailView(postID: destination.postID)
        }
    }
}
