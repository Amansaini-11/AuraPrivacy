//
//  PrivacyAudit.swift
//  Aura Privacy
//
//  SwiftData aggregate for a single imported App Privacy Report analysis run.
//

import Foundation
import SwiftData

/// One persisted audit derived from an on-device App Privacy Report export.
@Model
final class PrivacyAudit {
    @Attribute(.unique) var id: UUID
    /// When the export was analyzed (maps from legacy `createdAt` on disk).
    @Attribute(originalName: "createdAt") var date: Date
    /// Holistic score from 0 (critical exposure) to 100 (healthy baseline).
    var safetyScore: Int
    /// Short narrative suitable for dashboard hero copy.
    var summaryText: String
    /// Original filename chosen during import (optional).
    var sourceFilename: String?
    /// Raw line count processed for transparency/debugging.
    var parsedRecordCount: Int
    
    @Relationship(deleteRule: .cascade, inverse: \AppRiskProfile.audit)
    var profiles: [AppRiskProfile]
    
    init(
        id: UUID = UUID(),
        date: Date = .now,
        safetyScore: Int,
        summaryText: String,
        sourceFilename: String? = nil,
        parsedRecordCount: Int,
        profiles: [AppRiskProfile] = []
    ) {
        self.id = id
        self.date = date
        self.safetyScore = safetyScore
        self.summaryText = summaryText
        self.sourceFilename = sourceFilename
        self.parsedRecordCount = parsedRecordCount
        self.profiles = profiles
    }
}
