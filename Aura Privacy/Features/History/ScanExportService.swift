//
//  ScanExportService.swift
//  Aura Privacy
//
//  Renders shareable assets for a single historical audit (JSON / NDJSON / image / PDF).
//

import Foundation
import SwiftData
import SwiftUI
import UIKit

enum ScanExportService {
    
    @MainActor
    static func writeTempJSON(audit: PrivacyAudit) throws -> URL {
        let str = try AuraDataExporter.buildSingleAuditJSONString(audit)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("AuraScan-\(audit.id.uuidString).json")
        try str.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    
    @MainActor
    static func writeTempNDJSON(audit: PrivacyAudit) throws -> URL {
        let str = try AuraDataExporter.buildSingleAuditProfilesNDJSON(audit)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("AuraScan-\(audit.id.uuidString).ndjson")
        try str.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    
    @MainActor
    static func renderPremiumSnapshot(audit: PrivacyAudit, rows: [ScanActivityRow]) -> UIImage? {
        let height = captureHeight(for: rows.count)
        let content = HistoricalScanCaptureView(audit: audit, rows: rows)
            .frame(width: 390, height: height)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 3.0
        renderer.proposedSize = ProposedViewSize(width: 390, height: height)
        return renderer.uiImage
    }
    
    @MainActor
    static func writeTempPNG(audit: PrivacyAudit, rows: [ScanActivityRow]) throws -> URL? {
        guard let image = renderPremiumSnapshot(audit: audit, rows: rows),
              let data = image.pngData() else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("AuraScan-\(audit.id.uuidString).png")
        try data.write(to: url, options: .atomic)
        return url
    }
    
    @MainActor
    static func writeTempPDF(from image: UIImage) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("AuraScan-\(UUID().uuidString).pdf")
        let bounds = CGRect(origin: .zero, size: image.size)
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)
        try renderer.writePDF(to: url) { context in
            context.beginPage()
            image.draw(in: bounds)
        }
        return url
    }
    
    private static func captureHeight(for rowCount: Int) -> CGFloat {
        let base: CGFloat = 520
        let perRow: CGFloat = 116
        return max(900, base + CGFloat(max(0, rowCount)) * perRow)
    }
}

// MARK: - Share capture (ImageRenderer)

struct HistoricalScanCaptureView: View {
    let audit: PrivacyAudit
    let rows: [ScanActivityRow]
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.08, blue: 0.08)
            VStack(alignment: .leading, spacing: 18) {
                Text("Aura Privacy")
                    .font(.system(size: 28, weight: .black, design: .serif))
                    .foregroundStyle(.white)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Scan summary")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.55))
                    Text("Safety score \(audit.safetyScore)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(audit.date.formatted(date: .long, time: .shortened))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.gray)
                    if let name = audit.sourceFilename {
                        Text(name)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.65))
                            .lineLimit(2)
                    }
                    Text(audit.summaryText)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Text("App activity")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                
                ScanActivityCardList(rows: rows, showDividers: true, linksEnabled: false)
                
                Text("Data analyzed on-device only.")
                    .font(.caption2)
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
            }
            .padding(22)
        }
    }
}
