//
//  ShellScanCoordinator.swift
//  Aura Privacy
//
//  Full-screen import scanner overlay timing (2.5s window) + completion flash.
//

import Foundation
import SwiftUI

@Observable @MainActor
final class ShellScanCoordinator {
    
    var showFullScreenScanner = false
    var flashOpacity: Double = 0
    private(set) var flashBand: AuraGlobalScoreBand?
    
    func importStarted() {
        flashBand = nil
        flashOpacity = 0
        showFullScreenScanner = true
    }
    
    /// Waits until 2.5s from `importStarted`, flashes result tint, plays haptics once, then dismisses.
    func completeImportPhase(elapsed: TimeInterval, safetyScore: Int?, success: Bool) async {
        let remaining = max(0, 2.5 - elapsed)
        if remaining > 0 {
            try? await Task.sleep(for: .seconds(remaining))
        }
        
        let band: AuraGlobalScoreBand
        if success, let s = safetyScore {
            band = AuraGlobalScoreBand.band(forCurrentScore: s)
        } else {
            band = .red
        }
        flashBand = band
        
        withAnimation(.easeOut(duration: 0.14)) {
            flashOpacity = 1
        }
        try? await Task.sleep(for: .nanoseconds(160_000_000))
        
        if success {
            let s = safetyScore ?? 0
            if s > 80 {
                AuraHaptics.scanCompletedSuccess()
            } else {
                AuraHaptics.scanCompletedWarning()
            }
        } else {
            AuraHaptics.importFailed()
        }
        
        withAnimation(.easeOut(duration: 0.42)) {
            flashOpacity = 0
            showFullScreenScanner = false
        }
        try? await Task.sleep(for: .nanoseconds(450_000_000))
        flashBand = nil
    }
}
