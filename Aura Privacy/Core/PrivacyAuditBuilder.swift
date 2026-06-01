//
//  PrivacyAuditBuilder.swift
//  Aura Privacy
//
//  Merges deterministic scoring with optional guided generation output.
//

import Foundation

enum PrivacyAuditBuilder {
    
    /// Produces a fully-linked graph ready for insertion into SwiftData.
    static func makeAudit(
        parsed: ParsedPrivacyReport,
        aiInsights: [String: AIBundleInsight],
        filename: String?
    ) -> PrivacyAudit {
        let sortedBundles = parsed.aggregatesByBundle.values.sorted {
            $0.bundleID.localizedCaseInsensitiveCompare($1.bundleID) == .orderedAscending
        }
        
        var profiles: [AppRiskProfile] = []
        
        for aggregate in sortedBundles {
            let heuristic = RiskScoring.heuristicRisk(for: aggregate)
            let ai = aiInsights[aggregate.bundleID]
            
            let blendedRisk: Int
            let narrative: String
            
            if let ai {
                blendedRisk = Int((Double(heuristic) * 0.35) + (Double(ai.riskScore) * 0.65))
                    .clamped(to: 0...100)
                narrative = ai.insight
            } else {
                blendedRisk = heuristic
                narrative = heuristicFallback(for: aggregate)
            }
            
            let histogramJSON = encodeHistogram(aggregate.categoryCounts)
            
            let profile = AppRiskProfile(
                bundleID: aggregate.bundleID,
                displayName: RiskScoring.friendlyDisplayName(for: aggregate.bundleID),
                riskScore: blendedRisk,
                accessEventCount: aggregate.accessEvents,
                networkActivityCount: aggregate.networkEvents,
                categoryHistogramJSON: histogramJSON,
                aiInsight: narrative
            )
            
            profiles.append(profile)
        }
        
        let riskScores = profiles.map(\.riskScore)
        let safety = RiskScoring.safetyScore(fromRiskScores: riskScores)
        let summary = summarize(safetyScore: safety, profiles: profiles, recordCount: parsed.records.count)
        
        let audit = PrivacyAudit(
            safetyScore: safety,
            summaryText: summary,
            sourceFilename: filename,
            parsedRecordCount: parsed.records.count,
            profiles: []
        )
        
        for index in profiles.indices {
            profiles[index].audit = audit
        }
        
        audit.profiles = profiles
        return audit
    }
    
    private static func encodeHistogram(_ histogram: [String: Int]) -> String {
        guard let data = try? JSONEncoder().encode(histogram),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }
    
    private static func heuristicFallback(for aggregate: AppAccessAggregate) -> String {
        let topCategories = aggregate.categoryCounts
            .sorted { $0.value > $1.value }
            .prefix(2)
            .map { "\($0.key) (\($0.value)×)" }
            .joined(separator: ", ")
        
        if aggregate.networkEvents > aggregate.accessEvents / 2 {
            return "High outbound chatter (\(aggregate.networkEvents) hits)—audit domains you do not recognize."
        }
        
        if topCategories.isEmpty {
            return "Limited sensitive sensors touched—still review network endpoints regularly."
        }
        
        return "Most frequent sensors: \(topCategories). Validate whether each remains necessary."
    }
    
    private static func summarize(safetyScore: Int, profiles: [AppRiskProfile], recordCount: Int) -> String {
        let headline: String
        switch safetyScore {
        case 85...100: headline = "Overall posture looks resilient."
        case 65..<85: headline = "A few hotspots deserve attention."
        case 40..<65: headline = "Several apps show elevated exposure."
        default: headline = "Critical overlap across risky signals—take action soon."
        }
        
        let worst = profiles.max(by: { $0.riskScore < $1.riskScore })
        let worstDetail = worst.map { profile in
            " Highest pressure: \(profile.displayName) (\(profile.riskScore)/100)."
        } ?? ""
        
        return "\(headline)\(worstDetail) Parsed \(recordCount) privacy rows locally."
    }
}

private extension BinaryInteger {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
