//
//  Aura_PrivacyTests.swift
//  Aura PrivacyTests
//

import Foundation
import Testing

@testable import Aura_Privacy

struct Aura_PrivacyTests {
    
    @Test @MainActor func privacyReportParserCountsAccessRows() async throws {
        let sample = """
        {"type":"access","accessor":{"identifier":"com.example.app","type":"bundle"},"category":"camera","timestamp":"2025-01-01T12:00:00Z"}
        {"type":"networkActivity","accessor":{"identifier":"com.example.app","type":"bundle"},"domain":"telemetry.example"}
        """
        
        let parser = PrivacyReportParser()
        let parsed = try parser.parse(data: Data(sample.utf8))
        
        #expect(parsed.records.count == 2)
        let aggregate = try #require(parsed.aggregatesByBundle["com.example.app"])
        #expect(aggregate.accessEvents == 1)
        #expect(aggregate.networkEvents == 1)
        #expect(aggregate.categoryCounts["camera"] == 1)
    }
    
    @Test @MainActor func privacyReportParserSkipsIntervalEndAccessRows() async throws {
        let sample = """
        {"type":"access","accessor":{"identifier":"com.example.app","identifierType":"bundleID"},"category":"camera","identifier":"E2E9F4D8-0000-4000-8000-000000000001","kind":"intervalBegin","timeStamp":"2025-01-01T12:00:00Z"}
        {"type":"access","accessor":{"identifier":"com.example.app","identifierType":"bundleID"},"category":"camera","identifier":"E2E9F4D8-0000-4000-8000-000000000001","kind":"intervalEnd","timeStamp":"2025-01-01T12:00:05Z"}
        """
        
        let parser = PrivacyReportParser()
        let parsed = try parser.parse(data: Data(sample.utf8))
        
        let aggregate = try #require(parsed.aggregatesByBundle["com.example.app"])
        #expect(aggregate.accessEvents == 1)
        #expect(aggregate.categoryCounts["camera"] == 1)
    }
    
    @Test @MainActor func privacyReportParserUsesNetworkHitsField() async throws {
        let sample = """
        {"type":"networkActivity","bundleID":"com.example.app","domain":"api.example","hits":10,"timeStamp":"2025-01-01T12:00:00Z"}
        """
        
        let parser = PrivacyReportParser()
        let parsed = try parser.parse(data: Data(sample.utf8))
        
        let aggregate = try #require(parsed.aggregatesByBundle["com.example.app"])
        #expect(aggregate.networkEvents == 10)
        #expect(aggregate.domains["api.example"] == 10)
    }
    
    @Test @MainActor func heuristicRiskIncreasesWithSensitiveCategories() async throws {
        let heavy = AppAccessAggregate(
            bundleID: "com.heavy.app",
            accessEvents: 40,
            networkEvents: 2,
            categoryCounts: ["location": 20, "contacts": 10],
            domains: [:]
        )
        
        let light = AppAccessAggregate(
            bundleID: "com.light.app",
            accessEvents: 40,
            networkEvents: 2,
            categoryCounts: ["keyboard": 20],
            domains: [:]
        )
        
        #expect(RiskScoring.heuristicRisk(for: heavy) > RiskScoring.heuristicRisk(for: light))
    }
}
