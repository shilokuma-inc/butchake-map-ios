//
//  DraftEditView.swift
//  ButchakeMap
//

import SwiftUI

/// マイページから開く下書きの編集画面。入力・下書き保存・公開は投稿タブと同じフォームで行う
struct DraftEditView: View {
    @Environment(MockDataRepository.self) private var repository
    let postID: Post.ID

    var body: some View {
        DraftEditContent(viewModel: DraftEditViewModel(postID: postID, repository: repository))
    }
}

/// 編集画面の中身。ViewModel（開いた時点の下書き）は最初に渡されたものを @State で持ち続ける。
/// 公開で下書きではなくなっても、結果のアラートを閉じるまでフォームを出したままにするため
private struct DraftEditContent: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: DraftEditViewModel

    init(viewModel: DraftEditViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        if let draft = viewModel.draft {
            PostFormView(post: draft) { outcome in
                if DraftEditViewModel.closesForm(after: outcome) {
                    dismiss()
                }
            }
        } else {
            ContentUnavailableView {
                Label {
                    Text("Draft not found")
                } icon: {
                    EmptyStateIllustration(kind: .notFound)
                }
            } description: {
                Text("This draft may have been deleted or published.")
            }
            // 見つかったときのフォームと同じタイトルにする
            .navigationTitle(Text("Edit Post"))
        }
    }
}

#Preview {
    let repository = MockDataRepository.preview
    return NavigationStack {
        DraftEditView(postID: repository.drafts[0].id)
    }
    .environment(repository)
}

#Preview("見つからない") {
    NavigationStack {
        DraftEditView(postID: UUID())
    }
    .environment(MockDataRepository.preview)
}
