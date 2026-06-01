//
//  AuditHistoryView.swift
//  Aura Privacy
//

import SwiftData
import SwiftUI

struct AuditHistoryView: View {
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(AuraViewModel.self) private var viewModel
    @Query(sort: \PrivacyAudit.date, order: .reverse) private var audits: [PrivacyAudit]
    
    private var visibleAudits: [PrivacyAudit] {
        if subscriptions.isProSubscriber { return audits }
        let cutoff = Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? .distantPast
        return audits.filter { $0.date >= cutoff }
    }
    
    var body: some View {
        ZStack {
            AuraAmbientBackground(score: viewModel.currentScore)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    
                    if visibleAudits.isEmpty {
                        AuraGlassCard(cornerRadius: 22) {
                            ContentUnavailableView(
                                "No history yet",
                                systemImage: "clock.arrow.circlepath",
                                description: Text("Imported App Privacy Reports will appear here.")
                            )
                            .foregroundStyle(AuraRebuildTheme.foreground)
                        }
                    } else {
                        ForEach(visibleAudits) { audit in
                            NavigationLink(value: HistoricalScanNavID(auditID: audit.id)) {
                                historyRow(audit)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Scan history")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AuraRebuildTheme.foreground)
            Text("\(visibleAudits.count) scans recorded")
                .font(.system(size: 14))
                .foregroundStyle(AuraRebuildTheme.muted)
        }
    }
    
    private func historyRow(_ audit: PrivacyAudit) -> some View {
        let tone = auraTone(for: audit.safetyScore)
        return AuraGlassCard(cornerRadius: 22) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(tone.a.opacity(0.18))
                        .frame(width: 50, height: 50)
                    Circle()
                        .strokeBorder(tone.a.opacity(0.6), lineWidth: 1)
                        .frame(width: 50, height: 50)
                    Text("\(audit.safetyScore)")
                        .font(.system(size: 29/1.6, weight: .semibold))
                        .foregroundStyle(tone.a)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(auraScoreLabel(audit.safetyScore))
                        .font(.system(size: 30/2, weight: .semibold))
                        .foregroundStyle(AuraRebuildTheme.foreground)
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                        Text(audit.date.formatted(date: .abbreviated, time: .shortened))
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(AuraRebuildTheme.muted)
                    Text("\(audit.parsedRecordCount) apps · \(audit.profiles.filter { $0.riskScore >= 70 }.count) high-risk · \(audit.profiles.reduce(0) { $0 + $1.networkActivityCount }) blocked")
                        .font(.system(size: 13))
                        .foregroundStyle(AuraRebuildTheme.muted)
                }
                
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(AuraRebuildTheme.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
