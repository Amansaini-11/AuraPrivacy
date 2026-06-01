//
//  ScanActivityRow.swift
//  Aura Privacy
//
//  Shared row model + cell for dashboard App Activity and historical scan summaries.
//

import SwiftData
import SwiftUI

struct ScanActivityRow: Identifiable {
    let id: UUID
    let appName: String
    let warningLine: String
    let recommendationLine: String
    let trailingScore: String
    let accentColor: Color
    let trailingScoreColor: Color?
    let squircleFill: Color
    let iconSystemName: String
    let bullets: [RiskInsightCardModel]
    let severity: AppRiskSeverity?
    let profileNavID: UUID?
    
    var riskTextColor: Color {
        guard let severity else { return accentColor }
        switch severity {
        case .high:
            return Color(red: 1, green: 0.36, blue: 0.38)
        case .moderate:
            return Color(red: 1, green: 0.78, blue: 0.28)
        case .good:
            return Color(red: 0.32, green: 0.95, blue: 0.56)
        }
    }
    
    var severityScoreColor: Color {
        guard let severity else { return trailingScoreColor ?? accentColor }
        switch severity {
        case .high:
            return Color(red: 1, green: 0.28, blue: 0.3)
        case .moderate:
            return Color(red: 1, green: 0.74, blue: 0.22)
        case .good:
            return Color(red: 0.22, green: 0.9, blue: 0.5)
        }
    }
    
    var bulletTint: Color {
        guard let severity else { return accentColor }
        switch severity {
        case .high: return Color(red: 1, green: 0.32, blue: 0.34)
        case .moderate: return Color(red: 1, green: 0.58, blue: 0.2)
        case .good: return Color(red: 0.2, green: 0.9, blue: 0.48)
        }
    }
    
    init(
        id: UUID = UUID(),
        appName: String,
        warningLine: String,
        recommendationLine: String,
        trailingScore: String,
        accentColor: Color,
        trailingScoreColor: Color? = nil,
        squircleFill: Color,
        iconSystemName: String,
        bullets: [RiskInsightCardModel] = [],
        severity: AppRiskSeverity? = nil,
        profileNavID: UUID? = nil
    ) {
        self.id = id
        self.appName = appName
        self.warningLine = warningLine
        self.recommendationLine = recommendationLine
        self.trailingScore = trailingScore
        self.accentColor = accentColor
        self.trailingScoreColor = trailingScoreColor
        self.squircleFill = squircleFill
        self.iconSystemName = iconSystemName
        self.bullets = bullets
        self.severity = severity
        self.profileNavID = profileNavID
    }
    
    init(profile: AppRiskProfile) {
        let row = AppActivityRowModel(profile: profile)
        let band = AppRiskSquircleBand.colors(for: profile.riskScore)
        let bullets = AppActivityInsights.bullets(for: profile, max: 3)
        let trailingTint: Color? = {
            switch AppRiskSeverity.from(riskScore: profile.riskScore) {
            case .good: return band.accent
            default: return nil
            }
        }()
        self.init(
            id: profile.id,
            appName: row.appName,
            warningLine: row.riskDetail,
            recommendationLine: row.recommendation,
            trailingScore: "\(row.riskCount)",
            accentColor: band.accent,
            trailingScoreColor: trailingTint,
            squircleFill: band.fill,
            iconSystemName: row.systemIcon,
            bullets: bullets,
            severity: row.severity,
            profileNavID: profile.id
        )
    }
    
    static let referenceExamples: [ScanActivityRow] = [
        ScanActivityRow(
            id: UUID(uuidString: "00000001-0000-4000-8000-000000000001")!,
            appName: "TikTok",
            warningLine: "Clipboard read 24 times secretly",
            recommendationLine: "Recommendation: Revoke clipboard access in Settings",
            trailingScore: "88",
            accentColor: Color(red: 1, green: 0.22, blue: 0.26),
            squircleFill: AppRiskSquircleBand.colors(for: 88).fill,
            iconSystemName: "doc.on.clipboard",
            bullets: [
                RiskInsightCardModel(
                    systemImage: "doc.on.clipboard",
                    title: "Clipboard read 24 times secretly",
                    subtitle: ""
                ),
            ],
            severity: .high,
            profileNavID: nil
        ),
        ScanActivityRow(
            id: UUID(uuidString: "00000001-0000-4000-8000-000000000002")!,
            appName: "Instagram",
            warningLine: "Background camera access detected",
            recommendationLine: "Recommendation: Change Camera to 'While Using'",
            trailingScore: "55",
            accentColor: Color(red: 1, green: 0.52, blue: 0.1),
            squircleFill: AppRiskSquircleBand.colors(for: 55).fill,
            iconSystemName: "camera.fill",
            bullets: [
                RiskInsightCardModel(
                    systemImage: "camera.fill",
                    title: "Background camera access detected",
                    subtitle: ""
                ),
            ],
            severity: .moderate,
            profileNavID: nil
        ),
        ScanActivityRow(
            id: UUID(uuidString: "00000001-0000-4000-8000-000000000003")!,
            appName: "Facebook",
            warningLine: "Tracking across 12 other apps",
            recommendationLine: "Recommendation: Disable Allow Apps to Request to Track",
            trailingScore: "62",
            accentColor: Color(red: 1, green: 0.52, blue: 0.1),
            squircleFill: AppRiskSquircleBand.colors(for: 62).fill,
            iconSystemName: "waveform.path.ecg",
            bullets: [
                RiskInsightCardModel(
                    systemImage: "eye.fill",
                    title: "Tracking across 12 other apps",
                    subtitle: ""
                ),
            ],
            severity: .moderate,
            profileNavID: nil
        ),
        ScanActivityRow(
            id: UUID(uuidString: "00000001-0000-4000-8000-000000000004")!,
            appName: "Weather",
            warningLine: "Location accessed for forecasts",
            recommendationLine: "Standard behavior, no action needed",
            trailingScore: "12",
            accentColor: .white,
            trailingScoreColor: Color(red: 0.15, green: 0.88, blue: 0.42),
            squircleFill: AppRiskSquircleBand.colors(for: 12).fill,
            iconSystemName: "location.fill",
            bullets: [
                RiskInsightCardModel(
                    systemImage: "location.fill",
                    title: "Location accessed for forecasts",
                    subtitle: ""
                ),
            ],
            severity: .good,
            profileNavID: nil
        ),
    ]
}

// MARK: - Row chrome (dashboard + history)

private enum ScanActivityListTheme {
    static let card = Color(hex: "#2B2828").opacity(0.86)
    static let cardStroke = Color.white.opacity(0.12)
}

struct ScanActivityRowCell: View {
    let row: ScanActivityRow
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(row.squircleFill)
                    .frame(width: 52, height: 52)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
                    }
                    .shadow(color: row.accentColor.opacity(0.35), radius: 10, y: 3)
                Image(systemName: row.iconSystemName)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(row.appName)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                
                Text(row.warningLine)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(row.riskTextColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
                
                Text(row.recommendationLine)
                    .font(.caption2)
                    .foregroundStyle(Color.gray.opacity(0.95))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .trailing, spacing: 10) {
                Text(row.trailingScore)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(row.trailingScoreColor ?? row.severityScoreColor)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.gray.opacity(0.65))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

/// One large card with optional dividers — matches dashboard App Activity container.
struct ScanActivityCardList: View {
    let rows: [ScanActivityRow]
    var showDividers: Bool = true
    /// Set false when rendering a share image (no `NavigationLink` wrappers).
    var linksEnabled: Bool = true
    
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(rows) { row in
                rowCell(for: row)
            }
        }
    }
    
    @ViewBuilder
    private func rowCell(for row: ScanActivityRow) -> some View {
        let card = ScanActivityRowCell(row: row)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(ScanActivityListTheme.card)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(ScanActivityListTheme.cardStroke, lineWidth: 1)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.18), Color.white.opacity(0.02)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        
        if linksEnabled, let profileID = row.profileNavID {
            NavigationLink(value: ProfileNavID(id: profileID)) {
                card
            }
            .buttonStyle(.plain)
        } else {
            card
        }
    }
}
