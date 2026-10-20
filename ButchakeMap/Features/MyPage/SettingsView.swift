//
//  SettingsView.swift
//  ButchakeMap
//
//  マイページから開く設定。アカウントは無いので、「アカウントを削除」は確認ダイアログを出すだけで何も消さない
//

import SwiftUI

/// 設定画面（アプリのバージョン・表示言語の案内・書体のライセンス・アカウント削除のモック）
struct SettingsView: View {
    @State private var isConfirmingDeletion = false
    @State private var isShowingMockNotice = false

    /// Info.plist の CFBundleShortVersionString（取れなければ "-"）
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
    }

    var body: some View {
        Form {
            Section {
                LabeledContent {
                    Text(verbatim: appVersion)
                } label: {
                    Text("Version")
                }
                LabeledContent {
                    Text("Same as Device")
                } label: {
                    Text("Language")
                }
                NavigationLink {
                    FontLicensesView()
                } label: {
                    Text("Font Licenses")
                }
            } header: {
                Text("About This App")
                    .foregroundStyle(Color.textSecondary)
            } footer: {
                Text("The display language follows your device settings.")
                    .foregroundStyle(Color.textSecondary)
            }
            .listRowBackground(Color.surface)

            Section {
                Button(role: .destructive) {
                    isConfirmingDeletion = true
                } label: {
                    Text("Delete Account")
                }
            } footer: {
                Text("This is a mock app, so no data is actually deleted.")
                    .foregroundStyle(Color.textSecondary)
            }
            .listRowBackground(Color.surface)
        }
        // B-2: 地は紙、行は白、リンクなどの色はインク
        .scrollContentBackground(.hidden)
        .background(Color.paper)
        .tint(Color.brandPrimary)
        .navigationTitle(Text("Settings"))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete your account?", isPresented: $isConfirmingDeletion, titleVisibility: .visible) {
            Button(role: .destructive) {
                isShowingMockNotice = true
            } label: {
                Text("Delete Account")
            }
        } message: {
            Text("Your posts, saved posts, and drafts will be deleted.")
        }
        .alert("Account not deleted", isPresented: $isShowingMockNotice) {
            Button("OK") {}
        } message: {
            Text("This is a mock app, so nothing was deleted.")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(MockDataRepository.preview)
}
