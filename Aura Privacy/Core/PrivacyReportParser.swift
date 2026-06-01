//
//  PrivacyReportParser.swift
//  Aura Privacy
//
//  Parses newline-delimited JSON exports produced by iOS Settings ▸ App Privacy Report.
//

import Foundation

enum PrivacyReportParserError: Error, LocalizedError {
    case emptyFile
    case invalidEncoding
    case noRecognizedRecords
    
    var errorDescription: String? {
        switch self {
        case .emptyFile: return "The selected file does not contain any readable lines."
        case .invalidEncoding: return "The privacy export must be UTF-8 text."
        case .noRecognizedRecords: return "No recognizable privacy rows were found in this file."
        }
    }
}

/// Stateless parser that tolerates Apple's evolving dictionary shapes.
struct PrivacyReportParser: Sendable {
    
    /// Parses either NDJSON or a single JSON array/object payload.
    nonisolated func parse(data: Data, filename: String? = nil) throws -> ParsedPrivacyReport {
        guard !data.isEmpty else { throw PrivacyReportParserError.emptyFile }
        guard let text = String(data: data, encoding: .utf8) else {
            throw PrivacyReportParserError.invalidEncoding
        }
        
        var records: [PrivacyReportRecord] = []
        
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("[") {
            try appendJSONArray(trimmed, into: &records)
        } else {
            try appendNDJSON(trimmed, into: &records)
        }
        
        guard !records.isEmpty else { throw PrivacyReportParserError.noRecognizedRecords }
        
        var aggregates: [String: AppAccessAggregate] = [:]
        for record in records {
            guard let bundle = record.bundleID?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !bundle.isEmpty else { continue }
            
            var agg = aggregates[bundle] ?? AppAccessAggregate(
                bundleID: bundle,
                accessEvents: 0,
                networkEvents: 0,
                categoryCounts: [:],
                domains: [:]
            )
            
            if record.kind == "network" || record.type == "networkActivity" {
                agg.networkEvents += record.networkHits ?? 1
                if let domain = record.domain {
                    let bump = record.networkHits ?? 1
                    agg.domains[domain, default: 0] += bump
                }
            } else if record.type == "access" || record.category != nil {
                // Apple emits paired intervalBegin / intervalEnd rows per access; counting both doubles totals.
                if record.kind == "intervalEnd" {
                    continue
                }
                agg.accessEvents += 1
                if let category = record.category {
                    agg.categoryCounts[category, default: 0] += 1
                }
            }
            
            aggregates[bundle] = agg
        }
        
        guard !aggregates.isEmpty else { throw PrivacyReportParserError.noRecognizedRecords }
        
        return ParsedPrivacyReport(records: records, aggregatesByBundle: aggregates)
    }
    
    private nonisolated func appendNDJSON(_ text: String, into records: inout [PrivacyReportRecord]) throws {
        let lines = text.split(whereSeparator: \.isNewline)
        for line in lines {
            let lineString = String(line)
            guard let data = lineString.data(using: .utf8),
                  let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else { continue }
            
            if let record = decodeRecord(from: object) {
                records.append(record)
            }
        }
    }
    
    private nonisolated func appendJSONArray(_ text: String, into records: inout [PrivacyReportRecord]) throws {
        guard let data = text.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return }
        
        for object in json {
            if let record = decodeRecord(from: object) {
                records.append(record)
            }
        }
    }
    
    private nonisolated func decodeRecord(from json: [String: Any]) -> PrivacyReportRecord? {
        let kind = json["kind"] as? String
        let type = json["type"] as? String
        
        let category = firstString(json, keys: ["category", "resourceCategory"])
        
        let timestamp = firstDate(json, keys: ["timestamp", "timeStamp", "date", "firstTimeStamp"])
        
        let bundleFromRoot = firstString(json, keys: ["bundleIdentifier", "bundleId", "bundleID"])
        let accessorBundle = extractAccessorBundle(json["accessor"])
        let bundleID = bundleFromRoot ?? accessorBundle
        
        let domain = extractDomain(json)
        
        // Ignore rows that lack identifying info.
        guard bundleID != nil || domain != nil || category != nil else {
            return nil
        }
        
        let networkHits: Int?
        if type == "networkActivity" || kind == "network" {
            networkHits = firstInt(json, keys: ["hits"])
        } else {
            networkHits = nil
        }
        
        return PrivacyReportRecord(
            kind: kind,
            type: type,
            category: category,
            timestamp: timestamp,
            bundleID: bundleID,
            domain: domain,
            networkHits: networkHits
        )
    }
    
    private nonisolated func extractAccessorBundle(_ value: Any?) -> String? {
        guard let dict = value as? [String: Any] else { return nil }
        return firstString(dict, keys: ["bundleID", "bundleId", "identifier"])
    }
    
    private nonisolated func extractDomain(_ json: [String: Any]) -> String? {
        if let domain = firstString(json, keys: ["domain", "host", "hostname"]) {
            return domain
        }
        if let nested = json["networkActivity"] as? [String: Any] {
            return firstString(nested, keys: ["domain", "host"])
        }
        return nil
    }
    
    private nonisolated func firstInt(_ dict: [String: Any], keys: [String]) -> Int? {
        for key in keys {
            if let value = dict[key] as? Int { return value }
            if let value = dict[key] as? NSNumber { return value.intValue }
        }
        return nil
    }
    
    private nonisolated func firstString(_ dict: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = dict[key] as? String { return value }
            if let value = dict[key] as? NSString { return value as String }
        }
        return nil
    }
    
    private nonisolated func firstDate(_ dict: [String: Any], keys: [String]) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        for key in keys {
            guard let raw = dict[key] as? String else { continue }
            if let date = formatter.date(from: raw) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: raw) { return date }
        }
        return nil
    }
}
