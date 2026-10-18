//
//  SpotPhotoPickerRow.swift
//  ButchakeMap
//

import PhotosUI
import SwiftUI

/// 投稿作成フォームのスポットの写真の行。PhotosPicker で 1 枚選び、選び直し・削除ができる。
/// PhotosPicker は別プロセスで動くので、写真ライブラリへのアクセス許可は求めない
struct SpotPhotoPickerRow: View {
    /// 選んである写真（縮小・JPEG 圧縮済み）。nil なら未選択
    let photoData: Data?
    let onPick: (Data) -> Void
    let onRemove: () -> Void

    /// PhotosPicker で選んだ項目。読み込み終えたら nil に戻し、同じ写真も選び直せるようにする
    @State private var selection: PhotosPickerItem?
    @State private var isLoading = false
    @State private var loadFailed = false

    var body: some View {
        if let photoData {
            SpotPhotoImage(data: photoData)
                .frame(height: 160)
                .clipShape(.rect(cornerRadius: 8))
        }
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // PhotosPicker の label は MainActor の外で組み立てられるので、@State は label の外で読む
                PhotosPicker(selection: $selection, matching: .images) {
                    if photoData == nil {
                        Label("Add Photo", systemImage: "photo.badge.plus")
                    } else {
                        Label("Choose Another Photo", systemImage: "photo.on.rectangle")
                    }
                }
                .disabled(isLoading)
                Spacer(minLength: 0)
                if isLoading {
                    ProgressView()
                }
            }
            if loadFailed {
                Text("Couldn't load the photo.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        // 選び直したら前の読み込みは取り消され、後から選んだ写真だけが残る
        .task(id: selection) {
            await load()
        }
        if photoData != nil {
            Button("Remove Photo", systemImage: "trash", role: .destructive) {
                loadFailed = false
                onRemove()
            }
        }
    }

    private func load() async {
        guard let selection else {
            return
        }
        isLoading = true
        loadFailed = false
        let data = await SpotPhotoProcessor.loadJPEGData(from: selection)
        guard !Task.isCancelled else {
            return
        }
        isLoading = false
        if let data {
            onPick(data)
        } else {
            loadFailed = true
        }
        self.selection = nil
    }
}

#Preview {
    Form {
        Section("Spot 1") {
            SpotPhotoPickerRow(photoData: nil, onPick: { _ in }, onRemove: {})
        }
        Section("Spot 2") {
            SpotPhotoPickerRow(
                photoData: UIImage(systemName: "photo")?.pngData(),
                onPick: { _ in },
                onRemove: {}
            )
        }
    }
    .environment(MockDataRepository.preview)
}
