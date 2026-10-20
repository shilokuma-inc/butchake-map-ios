//
//  B2PartScale.swift
//  ButchakeMap
//

import CoreGraphics

/// B-2 の形の決まった部品（スタンプ・路線図の駅の丸・発車標の札）を、文字の大きさの設定に合わせて丸ごと大きくする倍率。
/// 部品は `@ScaledMetric` の 1 を基にした倍率を受け取り、ここで上限を付けて丸や札の大きさに掛ける。
/// 中の文字は同じ文字のスタイルの `Font.custom(_:size:relativeTo:)` で大きくなるので、上限を超えた分だけ `fontAdjustment(_:max:)` で文字の基の大きさを下げ、
/// 丸や札と文字の比を保つ（`minimumScaleFactor` は念のための受け）
enum B2PartScale {
    /// 倍率を上限で止める（小さな文字の設定では 1 より小さくなり、部品も文字と同じだけ小さくなる）
    nonisolated static func clamped(_ scale: CGFloat, max maxScale: CGFloat) -> CGFloat {
        guard scale.isFinite, scale > 0 else {
            return 1
        }
        return min(scale, maxScale)
    }

    /// 文字の基の大きさに掛ける値。`Font.custom(_:size:relativeTo:)` は文字の大きさの設定の分（`scale`）だけ大きくなるので、
    /// 部品の倍率を上限で止めた分だけ小さくして、文字も部品と同じ倍率にする（上限までは 1）
    nonisolated static func fontAdjustment(_ scale: CGFloat, max maxScale: CGFloat) -> CGFloat {
        guard scale.isFinite, scale > 0 else {
            return 1
        }
        return clamped(scale, max: maxScale) / scale
    }
}
