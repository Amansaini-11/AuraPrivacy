//
//  HistoricalScanSummaryView.swift
//  Aura Privacy
//
//  Past-scan overview: same App Activity presentation as the dashboard, all apps, then per-app detail.
//

import SwiftData
import SwiftUI

struct HistoricalScanSummaryView: View {
    let auditID: UUID
    var namespace: Namespace.ID
    
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subscriptions
    
    @State private var resolvedAudit: PrivacyAudit?
    @State private var showExportOptions = false
    @State private var paywallPresented = false
    @State private var exportPayload: HistoricalExportPayload?
    @State private var exportError: String?
    
    private var rows: [ScanActivityRow] {
        guard let resolvedAudit else { return [] }
        return resolvedAudit.profiles
            .sorted { $0.riskScore > $1.riskScore }
            .map { ScanActivityRow(profile: $0) }
    }
    
    var body: some View {
        Group {
            if let resolvedAudit {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Safety \(resolvedAudit.safetyScore)")
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(.primary)
                            Text(resolvedAudit.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            if let name = resolvedAudit.sourceFilename {
                                Text(name)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(2)
                            }
                            Text(resolvedAudit.summaryText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("App Activity")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)
                            
                            if rows.isEmpty {
                                Text("No per-app profiles for this scan.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                ScanActivityCardList(rows: rows, showDividers: true, linksEnabled: true)
                            }
                        }
                        
                        Text("Data is analyzed locally on your device. Aura never uploads your privacy report.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
                .scrollIndicators(.hidden)
            } else {
                ContentUnavailableView("Scan not found", systemImage: "doc.text.magnifyingglass")
            }
        }
        .navigationTitle("Scan detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    guard subscriptions.isProSubscriber else {
                        paywallPresented = true
                        return
                    }
                    showExportOptions = true
                } label: {
                    Label("Download scan", systemImage: "arrow.down.circle")
                }
            }
        }
        .confirmationDialog("Export this scan", isPresented: $showExportOptions, titleVisibility: .visible) {
            Button("JSON (standard)") {
                Task { await exportJSON() }
            }
            Button("NDJSON (profile rows)") {
                Task { await exportNDJSON() }
            }
            Button("Premium image (PNG) & PDF") {
                Task { await exportPremium() }
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(item: $exportPayload) { payload in
            HistoricalScanShareSheet(activityItems: payload.items)
        }
        .sheet(isPresented: $paywallPresented) {
            PaywallView()
                .environment(subscriptions)
        }
        .alert("Export", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } })
        ) {
            Button("OK", role: .cancel) { exportError = nil }
        } message: {
            Text(exportError ?? "")
        }
        .task(id: auditID) {
            await loadAudit()
        }
    }
    
    @MainActor
    private func loadAudit() async {
        let targetID = auditID
        let descriptor = FetchDescriptor<PrivacyAudit>(
            predicate: #Predicate<PrivacyAudit> { $0.id == targetID }
        )
        resolvedAudit = try? modelContext.fetch(descriptor).first
    }
    
    @MainActor
    private func exportJSON() async {
        guard let audit = resolvedAudit else { return }
        do {
            let url = try ScanExportService.writeTempJSON(audit: audit)
            exportPayload = HistoricalExportPayload(items: [url])
        } catch {
            exportError = error.localizedDescription
        }
    }
    
    @MainActor
    private func exportNDJSON() async {
        guard let audit = resolvedAudit else { return }
        do {
            let url = try ScanExportService.writeTempNDJSON(audit: audit)
            exportPayload = HistoricalExportPayload(items: [url])
        } catch {
            exportError = error.localizedDescription
        }
    }
    
    @MainActor
    private func exportPremium() async {
        guard let audit = resolvedAudit else { return }
        do {
            guard let pngURL = try ScanExportService.writeTempPNG(audit: audit, rows: rows),
                  let image = UIImage(contentsOfFile: pngURL.path) else {
                exportError = "Could not render premium snapshot."
                return
            }
            let pdfURL = try ScanExportService.writeTempPDF(from: image)
            exportPayload = HistoricalExportPayload(items: [pngURL, pdfURL])
        } catch {
            exportError = error.localizedDescription
        }
    }
}

private struct HistoricalExportPayload: Identifiable {
    let id = UUID()
    let items: [Any]
}

private struct HistoricalScanShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
