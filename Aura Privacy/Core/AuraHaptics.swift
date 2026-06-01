//
//  AuraHaptics.swift
//  Aura Privacy
//
//  Centralized UIKit feedback generators for scan rhythm and completion cues.
//

import UIKit

enum AuraHaptics {
    private static let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private static let notification = UINotificationFeedbackGenerator()
    
    private static var hapticsEnabled: Bool {
        if UserDefaults.standard.object(forKey: "hapticsEnabled") == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: "hapticsEnabled")
    }
    
    static func prepareForScan() {
        guard hapticsEnabled else { return }
        rigidImpact.prepare()
        notification.prepare()
    }
    
    /// Soft periodic tick while a privacy import is running (~Apple Taptic rhythm).
    static func scanPulseTick() {
        guard hapticsEnabled else { return }
        rigidImpact.prepare()
        rigidImpact.impactOccurred(intensity: 0.42)
    }
    
    static func scanCompletedSuccess() {
        guard hapticsEnabled else { return }
        notification.prepare()
        notification.notificationOccurred(.success)
    }
    
    static func scanCompletedWarning() {
        guard hapticsEnabled else { return }
        notification.prepare()
        notification.notificationOccurred(.warning)
    }
    
    static func importFailed() {
        guard hapticsEnabled else { return }
        notification.prepare()
        notification.notificationOccurred(.error)
    }
}
