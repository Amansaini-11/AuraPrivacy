//
//  PrivacyReportModels.swift
//  Aura Privacy
//
//  Value types produced by `PrivacyReportParser` before persistence / AI enrichment.
//

import Foundation

/// Raw statistics gathered while scanning an export file.
struct ParsedPrivacyReport: Sendable {
    var records: [PrivacyReportRecord]
    var aggregatesByBundle: [String: AppAccessAggregate]
}

/// One decoded row from App Privacy Report NDJSON — keys mirror Apple's export loosely
/// so older/newer formats remain ingestible.
struct PrivacyReportRecord: Sendable {
    let kind: String?
    let type: String?
    let category: String?
    let timestamp: Date?
    let bundleID: String?
    let domain: String?
    /// Present on `networkActivity` rows — Apple's export counts contacts via `hits`.
    let networkHits: Int?
}

/// Aggregated counters passed to heuristics + Foundation Models.
struct AppAccessAggregate: Codable, Sendable, Hashable {
    var bundleID: String
    var accessEvents: Int
    var networkEvents: Int
    /// Privacy-sensitive categories (camera, microphone, location, …).
    var categoryCounts: [String: Int]
    /// Observed network endpoints (best-effort).
    var domains: [String: Int]
    
    enum CodingKeys: String, CodingKey {
        case bundleID, accessEvents, networkEvents, categoryCounts, domains
    }
}
