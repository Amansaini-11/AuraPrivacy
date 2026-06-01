//
//  SettingsView.swift
//  Aura Privacy
//

import StoreKit
import SwiftData
import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview
    @Environment(AppShellState.self) private var appShellState
    @Environment(AuraViewModel.self) private var viewModel
    
    @AppStorage("appTheme") private var appThemeRaw = AppThemePreference.system.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("notificationsRemindersEnabled") private var notificationsRemindersEnabled = false
    @AppStorage("requireFaceID") private var requireFaceID = false
    
    @Query(sort: \PrivacyAudit.date, order: .reverse)
    private var audits: [PrivacyAudit]
    
    @State private var isResettingHistory = false
    @State private var showResetConfirmation = false
    @State private var exportPayload: SettingsSharePayload?
    @State private var exportError: String?
    @State private var paywallPresented = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                topBar
                upgradeCard
                
                sectionHeader("PRIVACY")
                settingsGroup {
                    toggleRow(icon: "shield", label: "Auto-scan weekly", isOn: $hapticsEnabled)
                    dividerLine
                    toggleRow(icon: "eye", label: "Tracker blocking", isOn: .constant(true))
                    dividerLine
                    toggleRow(icon: "lock", label: "Require Face ID", isOn: $requireFaceID)
                }
                
                sectionHeader("NOTIFICATIONS")
                settingsGroup {
                    toggleRow(icon: "bell", label: "High-risk alerts", isOn: $notificationsRemindersEnabled)
                    dividerLine
                    toggleRow(icon: "bell.badge", label: "Weekly reports", isOn: .constant(false))
                }
                .onChange(of: notificationsRemindersEnabled) { _, enabled in
                    if enabled {
                        Task { await requestNotificationAccess() }
                    }
                }
                
                sectionHeader("APPEARANCE")
                settingsGroup {
                    HStack {
                        iconTile("moon")
                        Text("Always dark mode")
                            .font(.system(size: 15))
                            .foregroundStyle(AuraRebuildTheme.foreground)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { appThemeRaw == AppThemePreference.dark.rawValue },
                            set: { appThemeRaw = $0 ? AppThemePreference.dark.rawValue : AppThemePreference.system.rawValue }
                        ))
                        .labelsHidden()
                        .tint(auraTone(for: viewModel.currentScore).a)
                    }
                    .padding(.vertical, 12)
                }
                
                sectionHeader("SUPPORT")
                settingsGroup {
                    linkRow(icon: "questionmark.circle", label: "Help & FAQ") {
                        openURL(URL(string: "https://www.apple.com/privacy/features/")!)
                    }
                    dividerLine
                    linkRow(icon: "envelope", label: "Contact us") {
                        openURL(URL(string: "mailto:support@auraprivacy.app")!)
                    }
                    dividerLine
                    linkRow(icon: "star", label: "Rate on the App Store") {
                        requestReview()
                    }
                    dividerLine
                    linkRow(icon: "square.and.arrow.up.on.square", label: "Export my data") {
                        exportUserData()
                    }
                }
                
                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset Data")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AuraRebuildTheme.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay { Capsule().strokeBorder(.white.opacity(0.1), lineWidth: 1) }
                .disabled(isResettingHistory)
                
                Text("Aura Privacy · v1.0.0")
                    .font(.system(size: 11))
                    .foregroundStyle(AuraRebuildTheme.muted)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .toolbar(.hidden, for: .navigationBar)
        .background(AuraAmbientBackground(score: viewModel.currentScore))
        .sheet(item: $exportPayload) { payload in
            ShareSheet(activityItems: payload.items)
        }
        .sheet(isPresented: $paywallPresented) {
            PaywallView()
        }
        .alert("Export", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } })
        ) {
            Button("OK", role: .cancel) { exportError = nil }
        } message: {
            Text(exportError ?? "")
        }
        .alert("Reset scan history?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                Task { await resetAuditHistory() }
            }
        } message: {
            Text("This removes all saved Aura Privacy audits from this device. You can import new reports at any time.")
        }
    }
    
    private var topBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Settings")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AuraRebuildTheme.foreground)
                Text("Tune your privacy preferences")
                    .font(.system(size: 14))
                    .foregroundStyle(AuraRebuildTheme.muted)
            }
            Spacer(minLength: 0)
            Button {
                paywallPresented = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("PRO")
                }
                .font(.system(size: 14, weight: .bold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(.black)
                .background(
                    LinearGradient(colors: [Color(hex: "#F5C758"), Color(hex: "#E89B3C")], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: Capsule()
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    private var upgradeCard: some View {
        Button {
            paywallPresented = true
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(.black.opacity(0.18))
                    .frame(width: 40, height: 40)
                    .overlay { Image(systemName: "star").foregroundStyle(.black) }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Upgrade to Pro")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Unlock real-time blocking & deep scans")
                        .font(.system(size: 14))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.black)
            .padding(16)
            .background(
                LinearGradient(colors: [Color(hex: "#F5B642"), Color(hex: "#F39024")], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 30, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .tracking(1.8)
            .foregroundStyle(AuraRebuildTheme.muted)
    }
    
    private func settingsGroup<Content: View>(@ViewBuilder _ content: @escaping () -> Content) -> some View {
        AuraGlassCard(cornerRadius: 24) {
            VStack(spacing: 0) {
                content()
            }
        }
    }
    
    private var dividerLine: some View {
        Rectangle().fill(.white.opacity(0.09)).frame(height: 1)
    }
    
    private func iconTile(_ icon: String) -> some View {
        Circle()
            .fill(.white.opacity(0.06))
            .frame(width: 32, height: 32)
            .overlay {
                Image(systemName: icon)
                    .foregroundStyle(auraTone(for: viewModel.currentScore).a)
                    .font(.system(size: 14, weight: .semibold))
            }
    }
    
    private func toggleRow(icon: String, label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            iconTile(icon)
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(AuraRebuildTheme.foreground)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(auraTone(for: viewModel.currentScore).a)
        }
        .padding(.vertical, 12)
    }
    
    private func linkRow(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                iconTile(icon)
                Text(label)
                    .font(.system(size: 15))
                    .foregroundStyle(AuraRebuildTheme.foreground)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(AuraRebuildTheme.muted)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
    
    @MainActor
    private func requestNotificationAccess() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }
    
    private func exportUserData() {
        do {
            let ndjson = try AuraDataExporter.buildNDJSONString(from: audits)
            let temp = FileManager.default.temporaryDirectory.appendingPathComponent("AuraPrivacyExport.ndjson")
            try ndjson.write(to: temp, atomically: true, encoding: .utf8)
            exportPayload = SettingsSharePayload(items: [temp])
        } catch {
            exportError = error.localizedDescription
        }
    }
    
    @MainActor
    private func resetAuditHistory() async {
        guard isResettingHistory == false else { return }
        isResettingHistory = true
        defer { isResettingHistory = false }
        
        do {
            try modelContext.delete(model: PrivacyAudit.self)
            try modelContext.save()
            appShellState.resetUIData()
            viewModel.resetForDataWipe()
            NotificationCenter.default.post(name: .auraScanHistoryDidReset, object: nil)
        } catch {
#if DEBUG
            print("Failed to reset audit history: \(error.localizedDescription)")
#endif
        }
    }
}

private struct SettingsSharePayload: Identifiable {
    let id = UUID()
    let items: [Any]
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
