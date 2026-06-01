//
//  AppRiskProfile.swift
//  Aura Privacy
//
//  Per-app risk slice stored under a parent `PrivacyAudit`.
//

import Foundation
import SwiftData

/// Risk-focused summary for a single app observed in the privacy export.
@Model
final class AppRiskProfile {
    @Attribute(.unique) var id: UUID
    var bundleID: String
    /// Best-effort display name (often derived from bundle ID tail until AI fills gaps).
    var displayName: String
    /// Local heuristic + AI blend, 0 (least concern in isolation) to 100 (elevated exposure).
    var riskScore: Int
    var accessEventCount: Int
    var networkActivityCount: Int
    /// JSON-encoded dictionary of category → count for structured detail screens.
    var categoryHistogramJSON: String
    /// On-device model narrative; never populated from network services.
    var aiInsight: String
    
    var audit: PrivacyAudit?
    
    init(
        id: UUID = UUID(),
        bundleID: String,
        displayName: String,
        riskScore: Int,
        accessEventCount: Int,
        networkActivityCount: Int,
        categoryHistogramJSON: String,
        aiInsight: String,
        audit: PrivacyAudit? = nil
    ) {
        self.id = id
        self.bundleID = bundleID
        self.displayName = displayName
        self.riskScore = riskScore
        self.accessEventCount = accessEventCount
        self.networkActivityCount = networkActivityCount
        self.categoryHistogramJSON = categoryHistogramJSON
        self.aiInsight = aiInsight
        self.audit = audit
    }
}

extension AppRiskProfile {
    /// Decodes the JSON histogram persisted for SwiftData compatibility.
    var categoryHistogram: [String: Int] {
        guard let data = categoryHistogramJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        return decoded
    }
}
