//
//  B2ButtonStyle.swift
//  ButchakeMap
//

import SwiftUI

/// B-2 のボタン（モックの .rail-button）。2pt の文字色の枠・角丸 8・下に 3pt の文字色の影で、押すと影の分だけ沈む
struct B2ButtonStyle: ButtonStyle {
    enum Kind {
        /// インクの地に白の文字（「投稿を見る」「公開する」など）
        case primary
        /// 白の地に文字色の文字（「マップで開く」など）
        case secondary
    }

    var kind: Kind = .primary

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        return configuration.label
            .labelStyle(B2ButtonLabelStyle())
            .font(.b2Heading(size: 15, relativeTo: .subheadline))
            .foregroundStyle(kind == .primary ? Color.surface : Color.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(kind == .primary ? Color.brandPrimary : Color.surface, in: .rect(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.textPrimary, lineWidth: 2)
            }
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.textPrimary)
                    .offset(y: isPressed ? 0 : 3)
            }
            .offset(y: isPressed ? 3 : 0)
            // 地と影を 1 枚にまとめてから薄くする（別々に薄くすると、白の地の下から影の黒が透けて灰色になる）
            .compositingGroup()
            .opacity(isEnabled ? 1 : 0.5)
            .contentShape(.rect(cornerRadius: 8))
    }
}

/// B-2 のボタンのアイコンと文字の間（モックの gap: 6px）
private struct B2ButtonLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon
            configuration.title
        }
    }
}

extension ButtonStyle where Self == B2ButtonStyle {
    /// B-2 のインクの地のボタン
    static var b2Primary: B2ButtonStyle { B2ButtonStyle(kind: .primary) }
    /// B-2 の白の地のボタン
    static var b2Secondary: B2ButtonStyle { B2ButtonStyle(kind: .secondary) }
}

#Preview {
    VStack(spacing: 20) {
        Button("Publish") {}
            .buttonStyle(.b2Primary)
        Button("Open in Maps", systemImage: "map") {}
            .buttonStyle(.b2Secondary)
        Button("Open in Maps", systemImage: "map") {}
            .buttonStyle(.b2Secondary)
            .disabled(true)
    }
    .padding()
    .background(Color.paper)
}

#Preview("大きな文字") {
    Button("Open in Maps", systemImage: "map") {}
        .buttonStyle(.b2Secondary)
        .padding()
        .background(Color.paper)
        .environment(\.dynamicTypeSize, .accessibility5)
}
