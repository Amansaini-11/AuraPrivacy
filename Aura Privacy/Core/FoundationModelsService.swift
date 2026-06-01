//
//  FoundationModelsService.swift
//  Aura Privacy
//
//  On-device Apple Intelligence analysis using `FoundationModels` — no external APIs.
//

import Foundation
import FoundationModels

struct AIBundleInsight: Sendable {
    let bundleID: String
    let riskScore: Int
    let insight: String
}

/// Coordinates `LanguageModelSession` usage with graceful degradation when Apple Intelligence is unavailable.
@MainActor
final class FoundationModelsPrivacyService {
    
    /// Returns AI-adjusted insights keyed by bundle identifier. Empty when models are unavailable or generation fails.
    func enrich(aggregates: [AppAccessAggregate]) async -> [String: AIBundleInsight] {
        guard !aggregates.isEmpty else { return [:] }
        guard #available(iOS 26.0, *) else { return [:] }
        
        switch SystemLanguageModel.default.availability {
        case .available:
            break
        default:
            return [:]
        }
        
        do {
            return try await performGuidedGeneration(aggregates: aggregates)
        } catch {
#if DEBUG
            print("FoundationModels enrichment failed: \(error.localizedDescription)")
#endif
            return [:]
        }
    }
    
    @available(iOS 26.0, *)
    private func performGuidedGeneration(aggregates: [AppAccessAggregate]) async throws -> [String: AIBundleInsight] {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(aggregates)
        let json = String(decoding: data, as: UTF8.self)
        
        let instructions = """
        You are Aura Privacy's on-device analyst. Only reason about the JSON aggregates supplied by the user.
        Never invent bundle identifiers—copy them exactly. Prefer actionable guidance over speculation.
        Flag suspicious breadth (many domains or sensitive sensors with high counts).
        """
        
        let session = LanguageModelSession(instructions: instructions)
        
        let prompt = """
        Aggregated App Privacy Report statistics (JSON array):
        \(json)
        
        Respond using guided generation. Ensure each bundle from the JSON appears exactly once.
        """
        
        let response = try await session.respond(to: prompt, generating: GuidedAuditInsights.self)
        let envelope = response.content
        
        var map: [String: AIBundleInsight] = [:]
        for row in envelope.insights {
            map[row.bundleID] = AIBundleInsight(bundleID: row.bundleID, riskScore: row.riskScore, insight: row.insight)
        }
        return map
    }
}

@available(iOS 26.0, *)
@Generable(description: "Envelope returned by the on-device privacy analyst model")
private struct GuidedAuditInsights {
    @Guide(description: "Exactly one entry per bundle copied from the supplied aggregates array")
    var insights: [GuidedBundleInsight]
}

@available(iOS 26.0, *)
@Generable(description: "Focused narrative for a single app bundle")
private struct GuidedBundleInsight {
    @Guide(description: "Bundle identifier copied verbatim from input JSON")
    var bundleID: String
    
    @Guide(description: "Relative exposure score where 0 is calm and 100 requires immediate attention", .range(0...100))
    var riskScore: Int
    
    @Guide(description: "Plain-language insight with two sentences maximum")
    var insight: String
}
