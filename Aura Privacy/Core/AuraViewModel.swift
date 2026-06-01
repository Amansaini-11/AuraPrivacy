//
//  AuraViewModel.swift
//  Aura Privacy
//
//  Shared root state to keep tab content stable and prevent visible resets.
//

import Foundation
import SwiftData

@Observable @MainActor
final class AuraViewModel {
    var currentScore: Int = 0
    var appActivities: [ScanActivityRow] = []
    
    func syncFromAudits(_ audits: [PrivacyAudit]) {
        guard let audit = audits.first else {
            currentScore = 0
            appActivities.removeAll()
            return
        }
        currentScore = audit.safetyScore
        appActivities = audit.profiles
            .sorted { $0.riskScore > $1.riskScore }
            .prefix(4)
            .map { ScanActivityRow(profile: $0) }
    }
    
    func resetForDataWipe() {
        currentScore = 0
        appActivities.removeAll()
    }
}
