//
//  MainTabShellView.swift
//  Aura Privacy
//
//  Root ZStack (no system TabView): mesh → content → floating glass tab bar → full-screen scanner.
//

import SwiftData
import SwiftUI

enum AuraRootTab: Int, CaseIterable, Identifiable {
    case history
    case auraScan
    case settings
    
    var id: Int { rawValue }
    
    var systemImage: String {
        switch self {
        case .history: return "clock.arrow.circlepath"
        case .auraScan: return "eye.fill"
        case .settings: return "gearshape.fill"
        }
    }
    
    var title: String {
        switch self {
        case .history: return "History"
        case .auraScan: return "Aura Scan"
        case .settings: return "Settings"
        }
    }
}

private enum MainTabShellMetrics {
    static let contentBottomInset: CGFloat = 100
}

struct MainTabShellView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppShellState.self) private var appShellState
    @Environment(AuraViewModel.self) private var viewModel
    @Environment(ShellScanCoordinator.self) private var shellScanCoordinator
    
    @Query(sort: \PrivacyAudit.date, order: .reverse)
    private var audits: [PrivacyAudit]
    
    @Namespace private var heroNamespace
    @Namespace private var tabSelectionNamespace
    @State private var selectedTab: AuraRootTab = .auraScan
    @State private var tabHapticTick = 0
    
    var body: some View {
        ZStack {
            AnimatedAuraBackground(currentScore: viewModel.currentScore)
            
            NavigationStack {
                DashboardView(namespace: heroNamespace)
                    .navigationDestination(for: HistoricalScanNavID.self) { route in
                        HistoricalScanSummaryView(auditID: route.auditID, namespace: heroNamespace)
                    }
                    .navigationDestination(for: ProfileNavID.self) { route in
                        profileDestination(route.id)
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(selectedTab == .auraScan ? 1 : 0)
            .allowsHitTesting(selectedTab == .auraScan)
            
            NavigationStack {
                AuditHistoryView()
                    .navigationDestination(for: HistoricalScanNavID.self) { route in
                        HistoricalScanSummaryView(auditID: route.auditID, namespace: heroNamespace)
                    }
                    .navigationDestination(for: ProfileNavID.self) { route in
                        profileDestination(route.id)
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(selectedTab == .history ? 1 : 0)
            .allowsHitTesting(selectedTab == .history)
            
            NavigationStack {
                SettingsView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(selectedTab == .settings ? 1 : 0)
            .allowsHitTesting(selectedTab == .settings)
            
            VStack {
                Spacer(minLength: 0)
                customFloatingTabBar
            }
            .padding(.bottom, 25)
            .background(Color.clear)
            
            if shellScanCoordinator.showFullScreenScanner {
                FullScreenScannerOverlay(coordinator: shellScanCoordinator)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .ignoresSafeArea()
        .tint(.blue)
        .sensoryFeedback(.selection, trigger: tabHapticTick)
        .onChange(of: selectedTab) { _, _ in
            tabHapticTick &+= 1
        }
        .onChange(of: audits.count) { _, _ in
            appShellState.syncFromAudits(audits)
            viewModel.syncFromAudits(audits)
        }
        .onChange(of: audits.first?.id) { _, _ in
            appShellState.syncFromAudits(audits)
            viewModel.syncFromAudits(audits)
        }
        .onAppear {
            appShellState.syncFromAudits(audits)
            viewModel.syncFromAudits(audits)
        }
    }
    
    @ViewBuilder
    private func profileDestination(_ id: UUID) -> some View {
        if let profile = fetchProfile(id: id) {
            AuditDetailView(profile: profile, namespace: heroNamespace)
        } else {
            Text("Unable to load profile.")
                .foregroundStyle(.secondary)
        }
    }
    
    private func fetchProfile(id: UUID) -> AppRiskProfile? {
        let descriptor = FetchDescriptor<AppRiskProfile>(
            predicate: #Predicate { $0.id == id }
        )
        return try? modelContext.fetch(descriptor).first
    }
    
    
    private var customFloatingTabBar: some View {
        let tone = auraTone(for: viewModel.currentScore)
        let glowAlignment: Alignment = {
            switch selectedTab {
            case .history: return .leading
            case .auraScan: return .center
            case .settings: return .trailing
            }
        }()
        return HStack(spacing: 0) {
            tabButton(tab: .history, icon: "clock.arrow.circlepath", title: "History", isCenter: false, tone: tone)
            tabButton(tab: .auraScan, icon: "eye.fill", title: "Aura Scan", isCenter: true, tone: tone)
            tabButton(tab: .settings, icon: "gearshape.fill", title: "Settings", isCenter: false, tone: tone)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(height: 68)
        .background {
            Capsule(style: .continuous)
                .fill(.clear)
                .background(.ultraThinMaterial, in: Capsule(style: .continuous))
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.34), .white.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .padding(.horizontal, 16)
        .compositingGroup()
        .overlay(alignment: glowAlignment) {
            Capsule()
                .fill(
                    RadialGradient(
                        colors: [tone.a.opacity(0.55), .clear],
                        center: .center,
                        startRadius: 4,
                        endRadius: 40
                    )
                )
                .frame(width: 84, height: 52)
                .blur(radius: 10)
                .offset(y: -2)
                .allowsHitTesting(false)
        }
    }
    
    
    
    @ViewBuilder
    private func tabButton(tab: AuraRootTab, icon: String, title: String, isCenter: Bool, tone: AuraScoreTone) -> some View {
        let isSelected = selectedTab == tab
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: isCenter ? 1 : 4) {
                Image(systemName: icon)
                    .font(.system(size: isCenter ? 19 : 18, weight: .semibold))
                    .foregroundStyle(isSelected ? AnyShapeStyle(tabSelectedGradient(tone: tone)) : AnyShapeStyle(Color.gray.opacity(0.9)))
                    .shadow(color: isSelected ? tone.a.opacity(0.8) : .clear, radius: isCenter ? 8 : 0)
                
                Text(title)
                    .font(.caption2.weight(isCenter && isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? (isCenter ? Color.white : tone.a) : .gray)
                    .shadow(color: isSelected ? tone.a.opacity(0.8) : .clear, radius: isCenter ? 8 : 0)
                
                Color.clear.frame(height: isCenter ? 9 : 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.white.opacity(0.055))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(.white.opacity(0.075), lineWidth: 1)
                        }
                        .matchedGeometryEffect(id: "selected-tab-pill", in: tabSelectionNamespace)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func tabSelectedGradient(tone: AuraScoreTone) -> LinearGradient {
        LinearGradient(
            colors: [
                tone.a,
                tone.b,
                tone.a.opacity(0.9),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
}
