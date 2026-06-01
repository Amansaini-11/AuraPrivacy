//
//  DashboardView.swift
//  Aura Privacy
//
//  Pixel-reference dashboard: dark cards, score ring, import CTA, app activity, scanning flow.
//

import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers

private enum DashboardTheme {
    static let shareCircle = Color.white.opacity(0.08)
    static let ringTrack = Color.white.opacity(0.1)
}

struct DashboardView: View {
    var namespace: Namespace.ID
    
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(AuraViewModel.self) private var viewModel
    @Environment(ShellScanCoordinator.self) private var shellScanCoordinator
    
    @Query(sort: \PrivacyAudit.date, order: .reverse)
    private var audits: [PrivacyAudit]
    
    @State private var dashboardModel = DashboardViewModel()
    
    @State private var isImporting = false
    @State private var analysisMessage: String?
    @State private var paywallPresented = false
    @State private var sharePayload: SharePayload?
    @State private var pulseAura = false
    @State private var shareExportURL: URL?
    @State private var glowAmount: CGFloat = 0
    @State private var glowRotation: Double = 0
    @State private var proShimmerX: CGFloat = -1.2
    @State private var promoShimmerX: CGFloat = -1.2
    @State private var selectedStatFilter: DashboardStatFilter?
    
    private let parser = PrivacyReportParser()
    private let aiService = FoundationModelsPrivacyService()
    
    private var displayLeadAudit: PrivacyAudit? {
        guard let first = audits.first else { return nil }
        if first.id == dashboardModel.suppressedLeadAuditID { return nil }
        return first
    }
    
    private var hasLeadAudit: Bool { displayLeadAudit != nil }
    
    private var heroScore: Int {
        if viewModel.appActivities.isEmpty { return 0 }
        return displayLeadAudit?.safetyScore ?? 0
    }
    
    private var severityTitle: String {
        guard hasLeadAudit else { return "No scan yet" }
        switch heroScore {
        case ..<60: return "Critical"
        case 60...80: return "Moderate"
        default: return "Good"
        }
    }
    
    private var severityIconName: String {
        guard hasLeadAudit else { return "doc.text.magnifyingglass" }
        switch heroScore {
        case ..<60: return "exclamationmark.shield.fill"
        case 60...80: return "exclamationmark.triangle.fill"
        default: return "checkmark.shield.fill"
        }
    }
    
    private var severityColor: Color {
        guard hasLeadAudit else { return Color.gray.opacity(0.75) }
        switch heroScore {
        case ..<60: return Color(red: 1, green: 0.22, blue: 0.26)
        case 60...80: return Color(red: 1, green: 0.52, blue: 0.1)
        default: return Color(red: 0.15, green: 0.88, blue: 0.42)
        }
    }
    
    private var scoreDescription: String {
        if let audit = displayLeadAudit {
            return audit.summaryText
        }
        return "Import an App Privacy Report from Settings to check if your Data is secure."
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            AuraAmbientBackground(score: heroScore)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerRow
                    mainScoreAndImportCard
                    statRow
                    proPromoCard
                    appActivityBlock
                    statusFooter
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                glowAmount = 1
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .auraScanHistoryDidReset)) { _ in
            dashboardModel.resetAfterHistoryWipe()
        }
        .task(id: displayLeadAudit?.id) {
            refreshShareExportURL()
        }
        .onChange(of: subscriptions.isProSubscriber) { _, _ in
            refreshShareExportURL()
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: allowedImportTypes,
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                Task { await handle(importURL: url) }
            case .failure(let error):
                analysisMessage = error.localizedDescription
            }
        }
        .alert("Analysis issue", isPresented: Binding(
            get: { analysisMessage != nil },
            set: { if !$0 { analysisMessage = nil } })
        ) {
            Button("OK", role: .cancel) { analysisMessage = nil }
        } message: {
            Text(analysisMessage ?? "")
        }
        .sheet(isPresented: $paywallPresented) {
            PaywallView()
                .environment(subscriptions)
        }
        .sheet(item: $sharePayload) { payload in
            ShareSheet(activityItems: payload.items)
        }
        .sheet(item: $selectedStatFilter) { filter in
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if filteredRows.isEmpty {
                            Text("No matching apps in this scan.")
                                .font(.subheadline)
                                .foregroundStyle(AuraRebuildTheme.muted)
                        } else {
                            ScanActivityCardList(rows: filteredRows, showDividers: true, linksEnabled: false)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
                .navigationTitle(filter.title)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    private var allowedImportTypes: [UTType] {
        var types: [UTType] = [.json, .plainText]
        if let ndjson = UTType(filenameExtension: "ndjson") {
            types.insert(ndjson, at: 0)
        }
        return types
    }
    
    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Aura Privacy")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(AuraRebuildTheme.foreground)
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 22, weight: .semibold))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, auraTone(for: heroScore).a.opacity(0.75))
                }
                Text("Your digital footprint, decoded.")
                    .font(.system(size: 14))
                    .foregroundStyle(AuraRebuildTheme.muted)
            }
            Spacer(minLength: 0)
            Button {
                paywallPresented = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                    Text("PRO")
                        .font(.system(size: 14, weight: .bold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(.black)
                .background(
                    LinearGradient(colors: [Color(hex: "#F5C758"), Color(hex: "#E89B3C")], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: Capsule()
                )
                .overlay {
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.42), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(width: 34)
                        .rotationEffect(.degrees(18))
                        .offset(x: geo.size.width * proShimmerX)
                        .blendMode(.screen)
                    }
                    .clipShape(Capsule())
                    .allowsHitTesting(false)
                }
            }
            .buttonStyle(.plain)
            .onAppear {
                withAnimation(.linear(duration: 2.6).repeatForever(autoreverses: false)) {
                    proShimmerX = 1.4
                }
            }
        }
    }
    
    private var sharePreviewImage: Image {
        guard let audit = displayLeadAudit,
              let ui = ShareBadgeRenderer.renderImage(audit: audit) else {
            return Image(systemName: "shield.lefthalf.filled")
        }
        return Image(uiImage: ui)
    }
    
    private func refreshShareExportURL() {
        shareExportURL = nil
        guard let audit = displayLeadAudit, subscriptions.isProSubscriber else { return }
        guard let data = ShareBadgeRenderer.renderImage(audit: audit)?.pngData() else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("AuraShare-\(audit.id.uuidString).png")
        try? data.write(to: url, options: .atomic)
        shareExportURL = url
    }
    
    private var mainScoreAndImportCard: some View {
        VStack(spacing: 16) {
            AuraScoreRing(score: heroScore, size: 240, lineWidth: 14)
                .frame(maxWidth: .infinity)
            Button {
                isImporting = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: dashboardModel.isAnalyzing ? "sparkle.magnifyingglass" : "sparkles")
                        .font(.headline.weight(.semibold))
                    Text(dashboardModel.isAnalyzing ? "Scanning..." : "Run new scan")
                        .font(.headline.weight(.bold))
                }
                .foregroundStyle(AuraRebuildTheme.foreground)
                .padding(.horizontal, 26)
                .padding(.vertical, 14)
                .background(Color.black.opacity(0.34), in: Capsule())
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(.white.opacity(0.1), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            HStack {
                Spacer()
                resetMainButton
            }
        }
    }
    
    private var statRow: some View {
        HStack(spacing: 12) {
            statCard(icon: "shield", label: "APPS", value: "\(displayLeadAudit?.parsedRecordCount ?? 0)", stat: .apps)
            statCard(icon: "exclamationmark.triangle", label: "HIGH RISK", value: "\(highRiskCount)", accent: AuraRebuildTheme.danger, stat: .highRisk)
            statCard(icon: "eye", label: "TRACKERS", value: "\(trackerCount)", stat: .trackers)
        }
    }
    
    private func statCard(icon: String, label: String, value: String, accent: Color = AuraRebuildTheme.foreground, stat: DashboardStatFilter) -> some View {
        Button {
            selectedStatFilter = stat
        } label: {
            AuraGlassCard(cornerRadius: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: icon).font(.system(size: 10, weight: .semibold))
                        Text(label).font(.system(size: 11, weight: .medium)).tracking(1.5)
                    }
                    .foregroundStyle(AuraRebuildTheme.muted)
                    Text(value)
                        .font(.system(size: 34/1.5, weight: .semibold).monospacedDigit())
                        .foregroundStyle(accent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.black.opacity(0.28))
            )
        }
        .buttonStyle(.plain)
    }
    
    private var highRiskCount: Int {
        displayLeadAudit?.profiles.filter { $0.riskScore >= 70 }.count ?? 0
    }
    
    private var trackerCount: Int {
        displayLeadAudit?.profiles.reduce(0) { $0 + $1.networkActivityCount } ?? 0
    }
    
    private var proPromoCard: some View {
        Button {
            paywallPresented = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("AURA PRIVACY PRO", systemImage: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(1.6)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                Text("Block hidden trackers in real time")
                    .font(.system(size: 38/1.8, weight: .bold))
                    .multilineTextAlignment(.leading)
                Text("Deep scans · Auto-block · Live alerts")
                    .font(.system(size: 14))
            }
            .padding(16)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient(colors: [Color(hex: "#F5C758"), Color(hex: "#F39024")], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay {
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.34), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: 44)
                    .rotationEffect(.degrees(16))
                    .offset(x: geo.size.width * promoShimmerX)
                    .blendMode(.screen)
                }
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .allowsHitTesting(false)
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.linear(duration: 2.8).repeatForever(autoreverses: false)) {
                promoShimmerX = 1.35
            }
        }
    }
    
    private var appActivityBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RECENT ACTIVITY")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.8)
                    .foregroundStyle(AuraRebuildTheme.muted)
                Spacer()
                NavigationLink(value: HistoricalScanNavID(auditID: displayLeadAudit?.id ?? UUID())) {
                    Text("See all")
                        .font(.system(size: 16/1.2, weight: .semibold))
                        .foregroundStyle(auraTone(for: heroScore).a)
                }
                .disabled(displayLeadAudit == nil)
                .opacity(displayLeadAudit == nil ? 0.5 : 1)
            }
            
            if viewModel.appActivities.isEmpty {
                EmptyStateDashboardView()
            } else {
                ScanActivityCardList(rows: activityRows, showDividers: true, linksEnabled: true)
            }
        }
    }
    
    private var statusFooter: some View {
        AuraGlassCard(cornerRadius: 18) {
            HStack(spacing: 10) {
                Image(systemName: "waveform.path.ecg")
                Text("\(auraScoreLabel(heroScore)) — last scan \(displayLeadAudit?.date.formatted(date: .omitted, time: .shortened) ?? "never")")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(AuraRebuildTheme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var activityRows: [ScanActivityRow] {
        viewModel.appActivities
    }
    
    private var allRowsFromLeadAudit: [ScanActivityRow] {
        guard let audit = displayLeadAudit else { return [] }
        return audit.profiles
            .sorted { $0.riskScore > $1.riskScore }
            .map { ScanActivityRow(profile: $0) }
    }
    
    private var filteredRows: [ScanActivityRow] {
        guard let selectedStatFilter else { return [] }
        let rows = allRowsFromLeadAudit
        switch selectedStatFilter {
        case .apps:
            return rows
        case .highRisk:
            return rows.filter { ($0.severity ?? .good) == .high }
        case .trackers:
            return rows.filter { $0.warningLine.localizedCaseInsensitiveContains("track") || $0.warningLine.localizedCaseInsensitiveContains("network") }
        }
    }
    
    private func handle(importURL: URL) async {
        let started = Date()
        shellScanCoordinator.importStarted()
        dashboardModel.beginScanning()
        let accessed = importURL.startAccessingSecurityScopedResource()
        defer {
            if accessed { importURL.stopAccessingSecurityScopedResource() }
        }
        do {
            let data = try Data(contentsOf: importURL)
            let parsed = try parser.parse(data: data, filename: importURL.lastPathComponent)
            let aggregates = Array(parsed.aggregatesByBundle.values)
            let aiMap = await aiService.enrich(aggregates: aggregates)
            let audit = PrivacyAuditBuilder.makeAudit(
                parsed: parsed,
                aiInsights: aiMap,
                filename: importURL.lastPathComponent
            )
            modelContext.insert(audit)
            try modelContext.save()
            dashboardModel.acknowledgeNewImport()
            await shellScanCoordinator.completeImportPhase(
                elapsed: Date().timeIntervalSince(started),
                safetyScore: audit.safetyScore,
                success: true
            )
            dashboardModel.endScanning(safetyScore: audit.safetyScore, success: true, playHaptics: false)
        } catch {
            await shellScanCoordinator.completeImportPhase(
                elapsed: Date().timeIntervalSince(started),
                safetyScore: nil,
                success: false
            )
            dashboardModel.endScanning(safetyScore: nil, success: false, playHaptics: false)
            analysisMessage = error.localizedDescription
        }
    }
    
    private func prepareShare() {
        guard displayLeadAudit != nil else { return }
        guard subscriptions.isProSubscriber else {
            paywallPresented = true
            return
        }
        guard let audit = displayLeadAudit,
              let image = ShareBadgeRenderer.renderImage(audit: audit) else {
            analysisMessage = "Unable to render badge."
            return
        }
        sharePayload = SharePayload(items: [image])
    }
}

extension DashboardView {
    private var resetMainButton: some View {
        Button {
            dashboardModel.clearCurrentDisplay(leadAuditID: audits.first?.id)
            viewModel.resetForDataWipe()
        } label: {
            Label("Reset main", systemImage: "arrow.counterclockwise.circle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AuraRebuildTheme.muted)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay { Capsule().strokeBorder(.white.opacity(0.1), lineWidth: 1) }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Score ring (red–orange for critical band)

private struct PixelScoreRing: View {
    let score: Int
    let lineWidth: CGFloat
    
    private var progress: CGFloat {
        CGFloat(max(0, min(100, score))) / 100.0
    }
    
    private var strokeGradient: AngularGradient {
        switch score {
        case ..<60:
            return AngularGradient(
                colors: [
                    Color(red: 1, green: 0.2, blue: 0.25),
                    Color(red: 1, green: 0.55, blue: 0.15),
                    Color(red: 1, green: 0.35, blue: 0.2),
                ],
                center: .center,
                startAngle: .degrees(-90),
                endAngle: .degrees(270)
            )
        case 60...80:
            return AngularGradient(
                colors: [
                    Color(red: 1, green: 0.75, blue: 0.1),
                    Color(red: 1, green: 0.45, blue: 0.12),
                    Color(red: 0.85, green: 0.75, blue: 0.2),
                ],
                center: .center,
                startAngle: .degrees(-90),
                endAngle: .degrees(270)
            )
        default:
            return AngularGradient(
                colors: [
                    Color(red: 0.15, green: 0.85, blue: 0.45),
                    Color(red: 0.2, green: 0.75, blue: 0.95),
                    Color(red: 0.25, green: 0.9, blue: 0.55),
                ],
                center: .center,
                startAngle: .degrees(-90),
                endAngle: .degrees(270)
            )
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(DashboardTheme.ringTrack, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(strokeGradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

private struct EmptyStateDashboardView: View {
    var body: some View {
        GlassEffectContainer(cornerRadius: 20) {
            VStack(spacing: 10) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Ready to Audit")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text("Import your privacy report to uncover hidden data access.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Scanning orb (radar + mesh)

private struct AuraHeroOrb: View {
    var model: DashboardViewModel
    let safetyScore: Int?
    @Binding var pulseAura: Bool
    var namespace: Namespace.ID
    
    @State private var burstScale: CGFloat = 1.0
    
    private var score: Int {
        safetyScore ?? 100
    }
    
    private var intensity: Double {
        Double(100 - score) / 100.0
    }
    
    var body: some View {
        ZStack {
            if model.isAnalyzing {
                scanningOrb
            } else if model.scanBurst != .none {
                burstOrb
            } else {
                idleOrb
            }
        }
        .padding(.vertical, 8)
        .onChange(of: model.scanBurst) { _, new in
            guard new != .none else {
                burstScale = 1.0
                return
            }
            burstScale = 0.88
            withAnimation(.spring(response: 0.42, dampingFraction: 0.62)) {
                burstScale = 1.12
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
                    burstScale = 1.0
                }
            }
        }
    }
    
    private var scanningOrb: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let wave = (sin(t * 1.8) + 1) * 0.5
            let breath = 1.0 + 0.1 * sin(t * 1.2)
            scanningOrbStack(wave: wave, breath: breath, time: t)
        }
        .accessibilityHidden(true)
    }
    
    private func scanningOrbStack(wave: Double, breath: CGFloat, time: TimeInterval) -> some View {
        ZStack {
            ForEach(0..<4, id: \.self) { ring in
                let base = 110 + CGFloat(ring) * 34
                let pulse = 1.0 + 0.06 * sin(time * 2.8 + Double(ring) * 0.9)
                Circle()
                    .stroke(Color.cyan.opacity(0.42 - Double(ring) * 0.09), lineWidth: 2)
                    .frame(width: base, height: base)
                    .scaleEffect(pulse)
                    .opacity(0.5 - Double(ring) * 0.1)
                    .rotationEffect(.degrees(time * (38 + Double(ring) * 18)))
            }
            
            Self.scanningMeshGradient(wave: wave)
                .blur(radius: 18)
                .clipShape(Circle())
                .frame(width: 168, height: 168)
            
            Circle()
                .strokeBorder(.white.opacity(0.4), lineWidth: 1.5)
                .background(Circle().fill(.thinMaterial))
                .frame(width: 140, height: 140)
                .overlay {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 52, weight: .medium))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.white.opacity(0.9), Color.white.opacity(0.35))
                        .shadow(color: .cyan.opacity(0.45), radius: 16)
                }
                .matchedGeometryEffect(id: "aura-central", in: namespace)
        }
        .scaleEffect(breath)
    }
    
    private static func scanningMeshGradient(wave: Double) -> MeshGradient {
        let pts: [SIMD2<Float>] = [
            .init(0, 0), .init(0.5, 0), .init(1, 0),
            .init(0, 0.5), .init(Float(0.45 + wave * 0.08), Float(0.45 + wave * 0.06)), .init(1, 0.5),
            .init(0, 1), .init(0.5, 1), .init(1, 1),
        ]
        let c0 = Color.cyan.opacity(0.55 + wave * 0.25)
        let c1 = Color.mint.opacity(0.5 + wave * 0.2)
        let c2 = Color.blue.opacity(0.45)
        let c3 = Color.purple.opacity(0.4 + wave * 0.15)
        let c4 = Color.teal.opacity(0.55)
        let c5 = Color.cyan.opacity(0.35)
        let c6 = Color.indigo.opacity(0.5)
        let c7 = Color.mint.opacity(0.45 + wave * 0.2)
        let c8 = Color.blue.opacity(0.5 + wave * 0.15)
        return MeshGradient(width: 3, height: 3, points: pts, colors: [c0, c1, c2, c3, c4, c5, c6, c7, c8])
    }
    
    private var burstOrb: some View {
        let isSafe = model.scanBurst == .safe
        return ZStack {
            if isSafe {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.green.opacity(0.95),
                                Color.mint.opacity(0.85),
                                Color.cyan.opacity(0.65),
                                Color.teal.opacity(0.35),
                            ],
                            center: .center,
                            startRadius: 4,
                            endRadius: 140
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 24)
            } else {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.red.opacity(0.95),
                                Color.orange.opacity(0.88),
                                Color.red.opacity(0.45),
                            ],
                            center: .center,
                            startRadius: 4,
                            endRadius: 140
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 24)
            }
            
            Circle()
                .strokeBorder(.white.opacity(0.45), lineWidth: 2)
                .background(
                    Circle().fill(
                        isSafe
                        ? Color.green.opacity(0.35).mix(with: Color.cyan, amount: 0.45)
                        : Color.red.opacity(0.5).mix(with: Color.orange, amount: 0.35)
                    )
                )
                .frame(width: 140, height: 140)
                .overlay {
                    Image(systemName: isSafe ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: (isSafe ? Color.cyan : Color.orange).opacity(0.85), radius: 20)
                }
                .matchedGeometryEffect(id: "aura-central", in: namespace)
        }
        .scaleEffect(burstScale)
        .accessibilityHidden(true)
    }
    
    private var idleOrb: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.green.opacity(0.65),
                            Color.red.opacity(0.35 + intensity * 0.45),
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 120
                    )
                )
                .frame(width: 160, height: 160)
                .blur(radius: 28)
                .scaleEffect(pulseAura ? 1.08 : 0.94)
                .opacity(pulseAura ? 1 : 0.78)
                .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: pulseAura)
                .onAppear { pulseAura = true }
            
            Circle()
                .strokeBorder(.white.opacity(0.35), lineWidth: 1.5)
                .background(Circle().fill(.thinMaterial))
                .frame(width: 140, height: 140)
                .overlay {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 52, weight: .medium))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.white.opacity(0.85), Color.white.opacity(0.35))
                        .shadow(color: .mint.opacity(0.55), radius: 18)
                }
                .matchedGeometryEffect(id: "aura-central", in: namespace)
        }
        .accessibilityHidden(true)
    }
}

private struct SharePayload: Identifiable {
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

private extension Color {
    func mix(with other: Color, amount: Double) -> Color {
        let clamped = max(0, min(amount, 1))
#if canImport(UIKit)
        let ui1 = UIColor(self)
        let ui2 = UIColor(other)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        ui1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        ui2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return Color(
            red: Double(r1 + (r2 - r1) * clamped),
            green: Double(g1 + (g2 - g1) * clamped),
            blue: Double(b1 + (b2 - b1) * clamped),
            opacity: Double(a1 + (a2 - a1) * clamped)
        )
#else
        return self
#endif
    }
}
private enum DashboardStatFilter: Identifiable {
    case apps
    case highRisk
    case trackers
    
    var id: String {
        switch self {
        case .apps: return "apps"
        case .highRisk: return "highRisk"
        case .trackers: return "trackers"
        }
    }
    
    var title: String {
        switch self {
        case .apps: return "All scanned apps"
        case .highRisk: return "High-risk apps"
        case .trackers: return "Apps with tracker activity"
        }
    }
}
