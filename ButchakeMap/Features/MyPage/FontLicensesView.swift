//
//  FontLicensesView.swift
//  ButchakeMap
//

import SwiftUI

/// 設定から開く、同梱している書体のライセンスの一覧
struct FontLicensesView: View {
    var body: some View {
        List {
            Section {
                ForEach(FontLicense.allCases) { font in
                    NavigationLink {
                        FontLicenseDetailView(font: font)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: font.familyName)
                                .foregroundStyle(Color.textPrimary)
                            Text(verbatim: font.licenseName)
                                .font(.footnote)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }
            } footer: {
                Text("The fonts bundled with this app are licensed under the SIL Open Font License 1.1.")
                    .foregroundStyle(Color.textSecondary)
            }
            .listRowBackground(Color.surface)
        }
        // B-2: 地は紙、行は白
        .scrollContentBackground(.hidden)
        .background(Color.paper)
        .tint(Color.brandPrimary)
        .navigationTitle(Text("Font Licenses"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 1 つの書体のライセンス文の全文
struct FontLicenseDetailView: View {
    let font: FontLicense

    var body: some View {
        ScrollView {
            if let text = font.licenseText() {
                LicenseTextView(text: text)
                    .cardStyle()
                    .padding()
            } else {
                ContentUnavailableView("Unable to load the license text.", systemImage: "doc.text")
            }
        }
        .background(Color.paper)
        .navigationTitle(Text(verbatim: font.familyName))
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// ライセンス文の本文。原文は 70〜80 字ごとに改行しているので、表示のときだけ段落の中の改行をつなぎ（FontLicense.reflowed(_:)）、
/// 画面の幅で折り返す。等幅をやめて本文の書体で出す。
/// 区切り線（-----）の行は、どの幅でも 1 行に収まらず折り返してしまうので、罫線として描く（飾りなので読み上げない）
private struct LicenseTextView: View {
    let text: String

    var body: some View {
        let lines = FontLicense.reflowed(text).components(separatedBy: "\n")
        VStack(alignment: .leading, spacing: 0) {
            ForEach(lines.indices, id: \.self) { index in
                let line = lines[index]
                if FontLicense.isSeparator(line) {
                    Rectangle()
                        .fill(Color.separatorLine)
                        .frame(height: 1)
                        .padding(.vertical, 8)
                        .accessibilityHidden(true)
                } else if line.isEmpty {
                    // 段落の間の空行（1 行分の高さをあける）
                    Text(verbatim: " ")
                        .accessibilityHidden(true)
                } else {
                    Text(verbatim: line)
                        .foregroundStyle(Color.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .font(.footnote)
        .textSelection(.enabled)
    }
}

#Preview("一覧") {
    NavigationStack {
        FontLicensesView()
    }
}

#Preview("全文") {
    NavigationStack {
        FontLicenseDetailView(font: .kaiseiDecol)
    }
}
