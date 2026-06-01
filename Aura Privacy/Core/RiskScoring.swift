//
//  RiskScoring.swift
//  Aura Privacy
//
//  Deterministic scoring used standalone or blended with on-device AI output.
//

import Foundation

enum RiskScoring: Sendable {
    
    /// Returns per-app heuristic risk (0 least exposure signal, 100 highest relative exposure).
    nonisolated static func heuristicRisk(for aggregate: AppAccessAggregate) -> Int {
        /// Categories Apple highlights in privacy reporting — higher weight implies more user impact.
        let sensitiveWeights: [String: Double] = [
            "location": 1.0,
            "contacts": 0.95,
            "photos": 0.75,
            "camera": 0.85,
            "microphone": 0.85,
            "mediaLibrary": 0.55,
            "bluetooth": 0.45,
            "motion": 0.45,
            "calendar": 0.65,
            "reminders": 0.55,
            "faceID": 0.35,
            "keyboard": 0.35,
            "screenRecording": 0.65,
            "clipboard": 0.55,
            "pasteboard": 0.55,
            "networkActivity": 0.25,
            "tracking": 0.85,
            "advertising": 0.75,
        ]
        
        var weighted: Double = 0
        
        for (category, count) in aggregate.categoryCounts {
            let normalizedCategory = category.lowercased()
            let weight = sensitiveWeights.first { key, _ in
                normalizedCategory.contains(key.lowercased())
            }?.value ?? 0.35
            
            weighted += Double(count) * weight
        }
        
        let networkSignal = Double(aggregate.networkEvents) * 0.15
        weighted += networkSignal
        
        // Rare domains imply breadth — lightly amplify when many distinct endpoints appear.
        let distinctDomains = aggregate.domains.count
        weighted += Double(distinctDomains) * 0.25
        
        // Soft saturation curve so extreme counts don't instantly peg to 100 without corroboration.
        let normalized = (weighted.squareRoot() * 12).rounded()
        return Int(min(max(normalized, 0), 100))
    }
    
    /// Computes dashboard safety score from risk profiles (inverse relationship).
    nonisolated static func safetyScore(fromRiskScores scores: [Int]) -> Int {
        guard !scores.isEmpty else { return 100 }
        let peak = scores.max() ?? 0
        let avg = Double(scores.reduce(0, +)) / Double(scores.count)
        
        // Weight worst actor heavily — reflects realistic user concern.
        let blended = (Double(peak) * 0.65) + (avg * 0.35)
        let inverted = 100 - blended
        return Int(min(max(inverted.rounded(), 0), 100))
    }
    
    nonisolated static func friendlyDisplayName(for bundleID: String) -> String {
        guard let tail = bundleID.split(separator: ".").last.map(String.init), !tail.isEmpty else {
            return bundleID
        }
        return tail.prefix(1).uppercased() + tail.dropFirst()
    }
}
