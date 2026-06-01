//
//  AuraNotifications.swift
//  Aura Privacy
//

import Foundation

extension Notification.Name {
    /// Posted after scan history is wiped from SwiftData so transient UI state can reset.
    static let auraScanHistoryDidReset = Notification.Name("auraScanHistoryDidReset")
}
