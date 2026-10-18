//
//  SpotLocationPickerView.swift
//  ButchakeMap
//

import MapKit
import SwiftUI

/// スポットの位置を選ぶ画面。地図の中心に固定したピンへ、地図を動かして場所を合わせる。
/// 現在地・住所検索は使わない
struct SpotLocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let order: Int
    let initialRegion: MKCoordinateRegion
    /// true なら、地図を初期表示の中心から動かすまで「この位置にする」を押せない
    let requiresMove: Bool
    let onPick: (CLLocationCoordinate2D) -> Void

    /// 初期表示の中心から動かしたとみなす緯度・経度の差（度）。約 10 m
    private static let moveTolerance = 0.0001

    /// 地図の中心（ピンの位置）。地図を動かし終えるたびに更新する
    @State private var center: CLLocationCoordinate2D

    init(
        order: Int,
        initialRegion: MKCoordinateRegion,
        requiresMove: Bool = false,
        onPick: @escaping (CLLocationCoordinate2D) -> Void
    ) {
        self.order = order
        self.initialRegion = initialRegion
        self.requiresMove = requiresMove
        self.onPick = onPick
        _center = State(initialValue: initialRegion.center)
    }

    /// 「この位置にする」を押せるか。初期表示のまま確定させたくないときは、中心が動いてから押せるようにする
    /// （onMapCameraChange は表示しただけでも呼ばれるので、呼ばれたかではなく中心の位置で判断する）
    private var canConfirm: Bool {
        guard requiresMove else {
            return true
        }
        return abs(center.latitude - initialRegion.center.latitude) > Self.moveTolerance
            || abs(center.longitude - initialRegion.center.longitude) > Self.moveTolerance
    }

    var body: some View {
        NavigationStack {
            Map(initialPosition: .region(initialRegion))
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                .onMapCameraChange(frequency: .onEnd) { context in
                    center = context.region.center
                }
                .overlay {
                    centerPin
                }
                .safeAreaInset(edge: .bottom) {
                    Text("Move the map to put the pin on the spot.")
                        .font(.footnote)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.regularMaterial, in: .capsule)
                        .padding(.bottom, 8)
                }
                .navigationTitle(Text("Spot \(order)"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Use This Location") {
                            onPick(center)
                            dismiss()
                        }
                        .bold()
                        .disabled(!canConfirm)
                    }
                }
        }
    }

    /// 地図の中心に立てるピン。針の先が中心に来るよう、アイコンの高さの半分だけ上にずらす
    private var centerPin: some View {
        Image(systemName: "mappin")
            .font(.system(size: 40))
            .foregroundStyle(Color.brandAccent)
            .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
            .alignmentGuide(VerticalAlignment.center) { dimensions in
                dimensions[.bottom]
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// 投稿作成フォームに出す、選んだ位置の小さな地図。触っても動かない
struct SpotLocationPreview: View {
    /// ピンに添える名前（スポット名）。未入力なら空
    let title: String
    let coordinate: CLLocationCoordinate2D

    var body: some View {
        Map(
            initialPosition: .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(
                        latitudeDelta: PostCreateViewModel.LocationSpan.selected,
                        longitudeDelta: PostCreateViewModel.LocationSpan.selected
                    )
                )
            ),
            interactionModes: []
        ) {
            Marker(title, coordinate: coordinate)
                .tint(Color.brandAccent)
        }
        // 選び直したら新しい位置で地図を作り直す（initialPosition は最初の 1 回しか効かないため）
        .id("\(coordinate.latitude),\(coordinate.longitude)")
        .frame(height: 140)
        .clipShape(.rect(cornerRadius: 8))
        .accessibilityHidden(true)
    }
}

#Preview {
    SpotLocationPickerView(order: 1, initialRegion: PostMapViewModel.japanRegion, requiresMove: true) { _ in }
        .environment(MockDataRepository.preview)
}

#Preview("選択済みのプレビュー") {
    SpotLocationPreview(title: "もりもり寿し", coordinate: CLLocationCoordinate2D(latitude: 36.5717, longitude: 136.6565))
        .padding()
        .environment(MockDataRepository.preview)
}
