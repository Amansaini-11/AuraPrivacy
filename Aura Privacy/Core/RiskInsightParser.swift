//
//  RiskInsightParser.swift
//  Aura Privacy
//
//  Turns model narrative text into structured "risk cards" for readable UI.
//

import Foundation

struct ParsedRiskInsight: Equatable {
    let riskLine: String
    let recommendationLine: String
    let contextLine: String
    let iconSystemName: String
}

struct RiskInsightCardModel: Identifiable, Equatable {
    let id: UUID
    let systemImage: String
    let title: String
    let subtitle: String
    
    init(id: UUID = UUID(), systemImage: String, title: String, subtitle: String) {
        self.id = id
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
    }
}

enum RiskInsightParser {
    
    /// Splits AI / heuristic copy into one or more cards with icon heuristics.
    static func cards(from insight: String) -> [RiskInsightCardModel] {
        let trimmed = insight.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            return [fallbackCard(from: "No additional narrative was generated for this app.")]
        }
        
        let chunks = splitIntoThoughts(trimmed)
        let mapped = chunks.enumerated().map { index, chunk in
            card(from: chunk, index: index)
        }
        return mapped.isEmpty ? [fallbackCard(from: trimmed)] : mapped
    }
    
    /// Extracts one display-ready risk row from free-form model narrative.
    static func primaryInsight(from insight: String) -> ParsedRiskInsight? {
        let trimmed = insight.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }
        
        let thoughts = splitIntoThoughts(trimmed)
        guard thoughts.isEmpty == false else { return nil }
        
        var recommendation = ""
        var context = ""
        var risk = ""
        
        for sentence in thoughts {
            let cleaned = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = cleaned.lowercased()
            
            if recommendation.isEmpty, lower.hasPrefix("recommendation:") {
                recommendation = cleaned
                continue
            }
            if recommendation.isEmpty,
               lower.contains("revoke") || lower.contains("disable") || lower.contains("change ") || lower.contains("limit ") || lower.contains("review ") {
                recommendation = cleaned.hasPrefix("Recommendation:")
                ? cleaned
                : "Recommendation: \(cleaned)"
                continue
            }
            
            if risk.isEmpty {
                risk = cleaned
            } else if context.isEmpty {
                context = cleaned
            }
        }
        
        if recommendation.isEmpty {
            recommendation = "Recommendation: Review permissions and background activity in Settings."
        }
        if risk.isEmpty {
            risk = thoughts[0]
        }
        
        let icon = symbol(for: risk)
        return ParsedRiskInsight(
            riskLine: risk,
            recommendationLine: recommendation,
            contextLine: context,
            iconSystemName: icon
        )
    }
    
    private static func splitIntoThoughts(_ text: String) -> [String] {
        let ns = text as NSString
        var parts: [String] = []
        ns.enumerateSubstrings(in: NSRange(location: 0, length: ns.length), options: [.bySentences]) { substring, _, _, _ in
            guard let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), s.isEmpty == false else { return }
            parts.append(s)
        }
        if parts.isEmpty {
            return text.split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .map { String($0) }
        }
        return parts
    }
    
    private static func card(from sentence: String, index: Int) -> RiskInsightCardModel {
        let icon = symbol(for: sentence)
        let (title, subtitle) = titleSubtitle(from: sentence, index: index)
        return RiskInsightCardModel(systemImage: icon, title: title, subtitle: subtitle)
    }
    
    private static func fallbackCard(from text: String) -> RiskInsightCardModel {
        RiskInsightCardModel(
            systemImage: "doc.text.magnifyingglass",
            title: "What we found",
            subtitle: text
        )
    }
    
    private static func titleSubtitle(from sentence: String, index: Int) -> (String, String) {
        let words = sentence.split(separator: " ").map(String.init)
        guard words.count > 6 else {
            let title = sentence.prefix(72).trimmingCharacters(in: .whitespacesAndNewlines)
            let rest = String(sentence.dropFirst(title.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            let subtitle = rest.isEmpty ? "Review permissions and background activity for this app." : rest
            return (String(title), subtitle)
        }
        
        let titleWordCount = min(10, max(4, words.count / 2))
        let title = words.prefix(titleWordCount).joined(separator: " ")
        let subtitle = words.dropFirst(titleWordCount).joined(separator: " ")
        return (title, subtitle)
    }
    
    static func symbol(for text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("location") || lower.contains("gps") { return "location.fill" }
        if lower.contains("camera") || lower.contains("photo") { return "camera.fill" }
        if lower.contains("microphone") || lower.contains("audio") { return "mic.fill" }
        if lower.contains("contact") || lower.contains("address book") { return "person.crop.circle.fill" }
        if lower.contains("network") || lower.contains("domain") || lower.contains("outbound") || lower.contains("chatter") {
            return "network"
        }
        if lower.contains("bluetooth") { return "dot.radiowaves.left.and.right" }
        if lower.contains("calendar") { return "calendar" }
        if lower.contains("clipboard") { return "doc.on.clipboard" }
        if lower.contains("sensor") || lower.contains("touch") { return "sensor.tag.radiowaves.forward" }
        if lower.contains("track") || lower.contains("frequent") { return "eye.fill" }
        if lower.contains("risk") || lower.contains("pressure") || lower.contains("elevated") { return "exclamationmark.shield.fill" }
        return "shield.lefthalf.filled"
    }
}
