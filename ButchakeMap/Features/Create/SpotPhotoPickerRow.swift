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
    /// 写真を読み込み中か
    let isLoading: Bool
    /// 直近の読み込みに失敗したか
    let loadFailed: Bool
    /// PhotosPicker で項目を選んだとき。読み込みは行が画面外に出ても続くよう、呼び出し側（ViewModel）で行う
    let onSelect: (PhotosPickerItem) -> Void
    let onRemove: () -> Void

    /// PhotosPicker で選んだ項目。渡したらすぐ nil に戻し、同じ写真も選び直せるようにする
    @State private var selection: PhotosPickerItem?

    var body: some View {
        if let photoData {
            SpotPhotoImage(data: photoData)
                .frame(height: 160)
                .clipShape(.rect(cornerRadius: 8))
        }
        VStack(alignment: .leading, spacing: 4) {
            HStack {
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
        .onChange(of: selection) {
            guard let selection else {
                return
            }
            onSelect(selection)
            self.selection = nil
        }
        if photoData != nil {
            Button("Remove Photo", systemImage: "trash", role: .destructive, action: onRemove)
        }
    }
}

#Preview {
    Form {
        Section("Spot 1") {
            SpotPhotoPickerRow(photoData: nil, isLoading: false, loadFailed: false, onSelect: { _ in }, onRemove: {})
        }
        Section("Spot 2") {
            SpotPhotoPickerRow(
                photoData: UIImage(systemName: "photo")?.pngData(),
                isLoading: false,
                loadFailed: false,
                onSelect: { _ in },
                onRemove: {}
            )
        }
        Section("Spot 3") {
            SpotPhotoPickerRow(
                photoData: nil,
                isLoading: true,
                loadFailed: true,
                onSelect: { _ in },
                onRemove: {}
            )
        }
    }
    .environment(MockDataRepository.preview)
}
