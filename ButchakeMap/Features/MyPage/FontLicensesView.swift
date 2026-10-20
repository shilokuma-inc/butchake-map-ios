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
                Text(verbatim: text)
                    .font(.footnote.monospaced())
                    .foregroundStyle(Color.textPrimary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
