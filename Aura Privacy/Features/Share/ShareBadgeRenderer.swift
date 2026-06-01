//
//  ShareBadgeRenderer.swift
//  Aura Privacy
//
//  Centralized ImageRenderer export for share sheets (dashboard + history).
//

import SwiftUI
import UIKit

enum ShareBadgeRenderer {
    @MainActor
    static func renderImage(audit: PrivacyAudit) -> UIImage? {
        let renderer = ImageRenderer(content: ExportCardView(audit: audit))
        renderer.scale = UITraitCollection.current.displayScale
        renderer.proposedSize = ProposedViewSize(width: 720, height: 960)
        return renderer.uiImage
    }
}
