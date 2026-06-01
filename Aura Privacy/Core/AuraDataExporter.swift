//
//  AuraDataExporter.swift
//  Aura Privacy
//
//  Builds a portable NDJSON snapshot of stored audits (one JSON object per line) for sharing
//  and for workflows that expect newline-delimited JSON like App Privacy Report tooling.
//

import Foundation
import SwiftData

enum AuraDataExporter {
    
    /// One audit per line, UTF-8 NDJSON (no outer array wrapper).
    static func buildNDJSONString(from audits: [PrivacyAudit]) throws -> String {
        var lines: [String] = []
        lines.reserveCapacity(audits.count)
        
        for audit in audits {
            let dict: [String: Any] = [
                "id": audit.id.uuidString,
                "date": ISO8601DateFormatter().string(from: audit.date),
                "safetyScore": audit.safetyScore,
                "summaryText": audit.summaryText,
                "sourceFilename": audit.sourceFilename as Any,
                "parsedRecordCount": audit.parsedRecordCount,
                "profiles": audit.profiles.map { profile in
                    [
                        "id": profile.id.uuidString,
                        "bundleID": profile.bundleID,
                        "displayName": profile.displayName,
                        "riskScore": profile.riskScore,
                        "accessEventCount": profile.accessEventCount,
                        "networkActivityCount": profile.networkActivityCount,
                        "aiInsight": profile.aiInsight,
                    ] as [String: Any]
                },
            ]
            let data = try JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys])
            guard let line = String(data: data, encoding: .utf8) else {
                throw NSError(domain: "AuraDataExporter", code: 1, userInfo: [NSLocalizedDescriptionKey: "Encoding failed"])
            }
            lines.append(line)
        }
        
        return lines.joined(separator: "\n")
    }
    
    /// Standard JSON (pretty) for one audit — used by in-app “Download scan”.
    static func buildSingleAuditJSONString(_ audit: PrivacyAudit) throws -> String {
        let data = try JSONSerialization.data(
            withJSONObject: singleAuditDictionary(audit),
            options: [.prettyPrinted, .sortedKeys]
        )
        guard let str = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "AuraDataExporter", code: 2, userInfo: [NSLocalizedDescriptionKey: "Encoding failed"])
        }
        return str
    }
    
    /// One JSON object per profile, newline-delimited.
    static func buildSingleAuditProfilesNDJSON(_ audit: PrivacyAudit) throws -> String {
        var lines: [String] = []
        lines.reserveCapacity(audit.profiles.count)
        for profile in audit.profiles {
            let dict: [String: Any] = [
                "auditId": audit.id.uuidString,
                "auditDate": ISO8601DateFormatter().string(from: audit.date),
                "safetyScore": audit.safetyScore,
                "profileId": profile.id.uuidString,
                "bundleID": profile.bundleID,
                "displayName": profile.displayName,
                "riskScore": profile.riskScore,
                "accessEventCount": profile.accessEventCount,
                "networkActivityCount": profile.networkActivityCount,
                "aiInsight": profile.aiInsight,
            ]
            let data = try JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys])
            guard let line = String(data: data, encoding: .utf8) else {
                throw NSError(domain: "AuraDataExporter", code: 3, userInfo: [NSLocalizedDescriptionKey: "Encoding failed"])
            }
            lines.append(line)
        }
        return lines.joined(separator: "\n")
    }
    
    private static func singleAuditDictionary(_ audit: PrivacyAudit) -> [String: Any] {
        [
            "id": audit.id.uuidString,
            "date": ISO8601DateFormatter().string(from: audit.date),
            "safetyScore": audit.safetyScore,
            "summaryText": audit.summaryText,
            "sourceFilename": audit.sourceFilename as Any,
            "parsedRecordCount": audit.parsedRecordCount,
            "profiles": audit.profiles.map { profile in
                [
                    "id": profile.id.uuidString,
                    "bundleID": profile.bundleID,
                    "displayName": profile.displayName,
                    "riskScore": profile.riskScore,
                    "accessEventCount": profile.accessEventCount,
                    "networkActivityCount": profile.networkActivityCount,
                    "aiInsight": profile.aiInsight,
                ] as [String: Any]
            },
        ]
    }
}
