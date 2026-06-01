//
//  AppShellState.swift
//  Aura Privacy
//
//  Global UI snapshot for the root mesh (`currentScore`) and hero activity rows.
//  Cleared explicitly on reset alongside SwiftData.
//

import Foundation
import SwiftData

@Observable @MainActor
final class AppShellState {
    
    /// Holistic safety score for the latest scan (0 when none).
    var currentScore: Int = 0
    
    /// Mirrors the dashboard’s top activity rows for the newest audit (up to 4).
    var currentAppActivity: [ScanActivityRow] = []
    
    func syncFromAudits(_ audits: [PrivacyAudit]) {
        guard let audit = audits.first else {
            resetUIData()
            return
        }
        currentScore = audit.safetyScore
        currentAppActivity = audit.profiles
            .sorted { $0.riskScore > $1.riskScore }
            .prefix(4)
            .map { ScanActivityRow(profile: $0) }
    }
    
    func resetUIData() {
        currentScore = 0
        currentAppActivity.removeAll()
    }
}
