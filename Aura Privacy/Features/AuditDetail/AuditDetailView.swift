//
//  AuditDetailView.swift
//  Aura Privacy
//
//  Detailed breakdown for a single `AppRiskProfile` — glass dashboard cards + risk wash.
//

import SwiftUI
import UIKit

struct AuditDetailView: View {
    @Bindable var profile: AppRiskProfile
    var namespace: Namespace.ID
    
    @Environment(SubscriptionManager.self) private var subscriptions
    @State private var sharePayload: AuditDetailSharePayload?
    @State private var paywallPresented = false
    
    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]
    
    var body: some View {
        ZStack {
            riskTintLayer
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    
                    RiskInsightCardStack(insight: profile.aiInsight, compact: false)
                        .padding(.vertical, 4)
                        .padding(12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
                        }
                    
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        sensorsCard
                        networkCard
                        dataLeaksCard
                    }
                    
                    histogramSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(profile.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .background(Color.clear)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    prepareShare()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .disabled(parentAudit == nil)
            }
        }
        .sheet(item: $sharePayload) { payload in
            ShareSheet(activityItems: payload.items)
        }
        .sheet(isPresented: $paywallPresented) {
            PaywallView()
                .environment(subscriptions)
        }
    }
    
    private var parentAudit: PrivacyAudit? {
        profile.audit
    }
    
    private func prepareShare() {
        guard let audit = parentAudit else { return }
        
        guard subscriptions.isProSubscriber else {
            paywallPresented = true
            return
        }
        
        guard let image = ShareBadgeRenderer.renderImage(audit: audit) else { return }
        
        sharePayload = AuditDetailSharePayload(items: [image])
    }
    
    private var riskTintLayer: some View {
        ZStack {
            Color.black.opacity(0.12)
            RadialGradient(
                colors: [
                    riskAccent.opacity(0.42),
                    Color.black.opacity(0.05),
                    .clear,
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 420
            )
            .blendMode(.plusLighter)
            
            LinearGradient(
                colors: [
                    riskAccent.opacity(0.12),
                    .clear,
                    riskAccent.opacity(0.08),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .allowsHitTesting(false)
    }
    
    private var riskAccent: Color {
        switch profile.riskScore {
        case 81...Int.max:
            return Color(red: 1, green: 0.22, blue: 0.28)
        case 40...80:
            return Color(red: 1, green: 0.55, blue: 0.12)
        default:
            return Color(red: 0.15, green: 0.88, blue: 0.42)
        }
    }
    
    private var header: some View {
        HStack(alignment: .center, spacing: 18) {
            ZStack {
                Circle()
                    .fill(auraGradient)
                    .frame(width: 96, height: 96)
                    .blur(radius: 18)
                    .opacity(0.85)
                
                Circle()
                    .strokeBorder(.white.opacity(0.35), lineWidth: 1.5)
                    .background(
                        Circle().fill(.ultraThinMaterial)
                    )
                    .frame(width: 96, height: 96)
                
                Text("\(profile.riskScore)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .accessibilityLabel("Risk score \(profile.riskScore) out of one hundred")
            }
            .matchedGeometryEffect(id: geometryID, in: namespace)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(profile.bundleID)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                
                Text(riskHeadline)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 10)
    }
    
    private var sensorsCard: some View {
        GlassEffectContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Sensors used", systemImage: "sensor.tag.radiowaves.forward")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)
                
                let rows = ProfileDetailMetrics.sensorRows(from: profile)
                if rows.isEmpty {
                    Text("No discrete sensor buckets in this export.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("These are sensitive sensors this app touched during the selected report.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 10) {
                            Image(systemName: row.icon)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(riskAccent)
                                .frame(width: 28, alignment: .center)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.title)
                                    .font(.subheadline.weight(.semibold))
                                Text("Used \(row.count) times in this report")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .gridCellColumns(2)
    }
    
    private var networkCard: some View {
        let net = ProfileDetailMetrics.networkSummary(from: profile)
        return GlassEffectContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Network activity", systemImage: "network")
                    .font(.headline.weight(.bold))
                
                Text("\(net.pings) total pings")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(.primary)
                
                Text(net.blurb)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Tip: If you do not recognize the network behavior, restrict background refresh for this app.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var dataLeaksCard: some View {
        let clip = ProfileDetailMetrics.clipboardTotal(from: profile)
        return GlassEffectContainer(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Data leaks & clipboard", systemImage: "doc.on.clipboard")
                    .font(.headline.weight(.bold))
                
                Text("\(clip) clipboard / pasteboard touches")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(clip > 0 ? Color.orange : Color.secondary)
                
                Text("Clipboard access can expose copied text. Keep it enabled only if the app truly needs it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var histogramSection: some View {
        let histogram = profile.categoryHistogram
        return Group {
            if histogram.isEmpty == false {
                GlassEffectContainer(cornerRadius: 22) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sensitive categories")
                            .font(.headline)
                        
                        ForEach(histogram.sorted(by: { $0.value > $1.value }), id: \.key) { entry in
                            HStack {
                                Text(entry.key.capitalized)
                                    .font(.subheadline)
                                Spacer()
                                Text("\(entry.value)×")
                                    .font(.subheadline.monospacedDigit().weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .gridCellColumns(2)
            }
        }
    }
    
    private var riskHeadline: String {
        switch profile.riskScore {
        case 81...Int.max: return "Elevated exposure — tighten permissions."
        case 40...80: return "Noticeable footprint — review what's necessary."
        default: return "Looks restrained relative to peers."
        }
    }
    
    private var auraGradient: LinearGradient {
        let tone = Double(profile.riskScore) / 100.0
        let safe = Color.green
        let danger = Color.red
        return LinearGradient(
            colors: [
                safe.opacity(1 - tone),
                danger.opacity(tone),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var geometryID: String {
        "aura-orb-\(profile.id.uuidString)"
    }
}

// MARK: - Metrics

private enum ProfileDetailMetrics {
    
    struct SensorRow: Equatable {
        let icon: String
        let title: String
        let count: Int
    }
    
    static func sensorRows(from profile: AppRiskProfile) -> [SensorRow] {
        var mic = 0, cam = 0, loc = 0, bt = 0, motion = 0
        for (key, value) in profile.categoryHistogram {
            let lower = key.lowercased()
            if lower.contains("microphone") || lower.contains("audio") { mic += value }
            if lower.contains("camera") || lower.contains("photo") { cam += value }
            if lower.contains("location") || lower.contains("gps") { loc += value }
            if lower.contains("bluetooth") { bt += value }
            if lower.contains("motion") { motion += value }
        }
        
        var rows: [SensorRow] = []
        if mic > 0 { rows.append(SensorRow(icon: "mic.fill", title: "Microphone", count: mic)) }
        if cam > 0 { rows.append(SensorRow(icon: "camera.fill", title: "Camera / photos", count: cam)) }
        if loc > 0 { rows.append(SensorRow(icon: "location.fill", title: "Location", count: loc)) }
        if bt > 0 { rows.append(SensorRow(icon: "dot.radiowaves.left.and.right", title: "Bluetooth", count: bt)) }
        if motion > 0 { rows.append(SensorRow(icon: "gyroscope", title: "Motion", count: motion)) }
        
        if rows.isEmpty, profile.accessEventCount > 0 {
            rows.append(
                SensorRow(
                    icon: "sensor.tag.radiowaves.forward",
                    title: "Combined sensor touches",
                    count: profile.accessEventCount
                )
            )
        }
        return rows
    }
    
    static func clipboardTotal(from profile: AppRiskProfile) -> Int {
        profile.categoryHistogram.reduce(0) { partial, pair in
            let lower = pair.key.lowercased()
            if lower.contains("clipboard") || lower.contains("pasteboard") {
                return partial + pair.value
            }
            return partial
        }
    }
    
    static func networkSummary(from profile: AppRiskProfile) -> (pings: Int, blurb: String) {
        let pings = profile.networkActivityCount
        let insight = profile.aiInsight.lowercased()
        if insight.contains("domain") || insight.contains("endpoint") || insight.contains("outbound") {
            return (pings, "This app contacted one or more domains/endpoints in the report window.")
        }
        if pings == 0 {
            return (0, "No outbound network activity was attributed to this app in this report.")
        }
        return (pings, "The app made repeated network calls. Verify this matches how often you used it.")
    }
}

private struct AuditDetailSharePayload: Identifiable {
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
