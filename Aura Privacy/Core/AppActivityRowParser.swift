//
//  AppActivityRowParser.swift
//  Aura Privacy
//
//  Builds premium "App Activity" row copy from `AppRiskProfile` + histogram + AI text.
//

import Foundation
import SwiftData
import SwiftUI

enum AppRiskSquircleBand {
    /// Icon tint bands: critical >80, moderate 40–79, safe <40 on the **risk** scale (higher = worse).
    static func colors(for riskScore: Int) -> (fill: Color, accent: Color) {
        switch riskScore {
        case 81...Int.max:
            return (
                Color(red: 0.92, green: 0.16, blue: 0.2),
                Color(red: 1, green: 0.22, blue: 0.26)
            )
        case 40...80:
            return (
                Color(red: 0.95, green: 0.52, blue: 0.12),
                Color(red: 1, green: 0.62, blue: 0.18)
            )
        default:
            return (
                Color(red: 0.12, green: 0.65, blue: 0.35),
                Color(red: 0.15, green: 0.88, blue: 0.42)
            )
        }
    }
}

enum AppRiskSeverity {
    case high
    case moderate
    case good
    
    static func from(riskScore: Int) -> AppRiskSeverity {
        switch riskScore {
        case 81...Int.max: return .high
        case 40...80: return .moderate
        default: return .good
        }
    }
}

enum AppActivityInsights {
    /// Action-oriented bullets for list rows (parsed AI + histogram fallbacks).
    static func bullets(for profile: AppRiskProfile, max: Int = 3) -> [RiskInsightCardModel] {
        var seen = Set<String>()
        var out: [RiskInsightCardModel] = []
        
        for card in RiskInsightParser.cards(from: profile.aiInsight) {
            let key = card.title.lowercased()
            if seen.insert(key).inserted {
                out.append(card)
            }
            if out.count >= max { return out }
        }
        
        for card in histogramCards(profile: profile) {
            let key = card.title.lowercased()
            if seen.insert(key).inserted {
                out.append(card)
            }
            if out.count >= max { return out }
        }
        
        if out.isEmpty {
            out.append(
                RiskInsightCardModel(
                    systemImage: "shield.lefthalf.filled",
                    title: "Review permissions for this app",
                    subtitle: "Import a fresh report after changing settings to verify improvements."
                )
            )
        }
        
        return out
    }
    
    private static func histogramCards(profile: AppRiskProfile) -> [RiskInsightCardModel] {
        let hist = profile.categoryHistogram
        guard hist.isEmpty == false else { return networkClipboardFallback(profile: profile) }
        
        let sorted = hist.sorted { $0.value > $1.value }
        return sorted.compactMap { key, count -> RiskInsightCardModel? in
            let lower = key.lowercased()
            let (icon, label): (String, String) = {
                if lower.contains("camera") || lower.contains("photo") {
                    return ("camera.fill", "Camera accessed \(count)× in this window")
                }
                if lower.contains("microphone") || lower.contains("audio") {
                    return ("mic.fill", "Microphone touched \(count)× in this window")
                }
                if lower.contains("location") || lower.contains("gps") {
                    return ("location.fill", "Location signal logged \(count)×")
                }
                if lower.contains("clipboard") || lower.contains("pasteboard") {
                    return ("doc.on.clipboard", "Clipboard / pasteboard activity \(count)×")
                }
                if lower.contains("contact") {
                    return ("person.crop.circle.fill", "Contacts access \(count)×")
                }
                if lower.contains("track") || lower.contains("advert") {
                    return ("eye.fill", "Tracking-related signals \(count)×")
                }
                if lower.contains("network") {
                    return ("network", "Network category hits \(count)×")
                }
                return ("sensor.tag.radiowaves.forward", "\(key.replacingOccurrences(of: "_", with: " ").capitalized) \(count)×")
            }()
            return RiskInsightCardModel(systemImage: icon, title: label, subtitle: "")
        }
    }
    
    private static func networkClipboardFallback(profile: AppRiskProfile) -> [RiskInsightCardModel] {
        var rows: [RiskInsightCardModel] = []
        if profile.networkActivityCount > 0 {
            rows.append(
                RiskInsightCardModel(
                    systemImage: "network",
                    title: "\(profile.networkActivityCount) network pings in export window",
                    subtitle: "Highlight unknown domains in Settings ▸ Privacy."
                )
            )
        }
        if profile.accessEventCount > 0 {
            rows.append(
                RiskInsightCardModel(
                    systemImage: "sensor.tag.radiowaves.forward",
                    title: "\(profile.accessEventCount) sensitive resource touches",
                    subtitle: "Compare counts with how actively you used the app."
                )
            )
        }
        return rows
    }
}

struct AppActivityRowModel: Identifiable, Equatable {
    let id: UUID
    let appName: String
    let riskDetail: String
    let riskCount: Int
    let recommendation: String
    let severity: AppRiskSeverity
    let systemIcon: String
    
    init(profile: AppRiskProfile) {
        let parsedInsight = Self.structuredInsight(profile: profile)
        let appSpecificIcon = Self.appIcon(for: profile.displayName, bundleID: profile.bundleID)
        self.id = profile.id
        self.appName = profile.displayName
        self.riskCount = profile.riskScore
        self.severity = AppRiskSeverity.from(riskScore: profile.riskScore)
        self.systemIcon = appSpecificIcon == "app.fill" ? (parsedInsight?.iconSystemName ?? appSpecificIcon) : appSpecificIcon
        self.riskDetail = Self.buildRiskDetail(profile: profile, parsedInsight: parsedInsight)
        self.recommendation = Self.buildRecommendation(
            severity: AppRiskSeverity.from(riskScore: profile.riskScore),
            parsedInsight: parsedInsight
        )
    }
    
    private static func appIcon(for name: String, bundleID: String) -> String {
        let key = (name + bundleID).lowercased()
        if key.contains("youtube") { return "play.rectangle.fill" }
        if key.contains("tiktok") { return "music.note.list" }
        if key.contains("instagram") { return "camera.aperture" }
        if key.contains("whatsapp") || key.contains("telegram") || key.contains("message") { return "bubble.left.and.bubble.right.fill" }
        if key.contains("facebook") || key.contains("meta") { return "person.3.fill" }
        if key.contains("x.com") || key.contains("twitter") { return "text.bubble.fill" }
        if key.contains("snapchat") { return "camera.viewfinder" }
        if key.contains("netflix") || key.contains("primevideo") || key.contains("disney") { return "tv.fill" }
        if key.contains("spotify") || key.contains("music") { return "music.note" }
        if key.contains("uber") || key.contains("lyft") || key.contains("maps") { return "car.fill" }
        if key.contains("google") || key.contains("chrome") || key.contains("gmail") { return "globe" }
        if key.contains("safari") { return "safari.fill" }
        if key.contains("amazon") || key.contains("shop") || key.contains("flipkart") { return "bag.fill" }
        if key.contains("bank") || key.contains("pay") || key.contains("wallet") { return "creditcard.fill" }
        if key.contains("camera") || key.contains("photo") { return "photo.fill" }
        if key.contains("weather") { return "cloud.sun.fill" }
        if key.contains("health") || key.contains("fitness") { return "heart.text.square.fill" }
        if key.contains("calendar") { return "calendar" }
        if key.contains("notes") { return "note.text" }
        return "app.fill"
    }
    
    private static func structuredInsight(profile: AppRiskProfile) -> ParsedRiskInsight? {
        RiskInsightParser.primaryInsight(from: profile.aiInsight)
    }
    
    private static func buildRiskDetail(profile: AppRiskProfile, parsedInsight: ParsedRiskInsight?) -> String {
        if let parsedInsight, parsedInsight.riskLine.count > 8 {
            return parsedInsight.riskLine
        }
        
        let hist = profile.categoryHistogram
        if let top = hist.max(by: { $0.value < $1.value }) {
            let label = top.key.replacingOccurrences(of: "_", with: " ").capitalized
            return "\(label) touched \(top.value)× in this export window — review if unexpected."
        }
        
        if profile.networkActivityCount > profile.accessEventCount {
            return "Network activity \(profile.networkActivityCount)× — verify outbound domains you trust."
        }
        
        return "Sensor & access events logged \(profile.accessEventCount)× — compare with how you use the app."
    }
    
    private static func buildRecommendation(severity: AppRiskSeverity, parsedInsight: ParsedRiskInsight?) -> String {
        if let recommendation = parsedInsight?.recommendationLine.trimmingCharacters(in: .whitespacesAndNewlines),
           recommendation.isEmpty == false {
            return recommendation
        }
        
        switch severity {
        case .high:
            return "Recommendation: revoke non-essential permissions and audit background refresh."
        case .moderate:
            return "Recommendation: trim location/photos access and review notification-driven launches."
        case .good:
            return "Recommendation: keep current posture; re-scan after major app updates."
        }
    }
}
