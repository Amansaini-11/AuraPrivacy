//
//  DashboardViewModel.swift
//  Aura Privacy
//
//  Home screen scan UI state, haptics, and non-destructive "clear current scan" display.
//

import Foundation
import SwiftUI

enum ScanBurst: Equatable {
    case none
    case safe
    case warning
}

@Observable @MainActor
final class DashboardViewModel {
    
    /// When set, the newest persisted audit is hidden from the hero / "latest" panels only.
    var suppressedLeadAuditID: UUID?
    
    var isAnalyzing: Bool = false
    var scanBurst: ScanBurst = .none
    
    private var scanTickTask: Task<Void, Never>?
    
    func beginScanning() {
        isAnalyzing = true
        scanBurst = .none
        AuraHaptics.prepareForScan()
        
        scanTickTask?.cancel()
        scanTickTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(1500))
                guard !Task.isCancelled, isAnalyzing else { break }
                AuraHaptics.scanPulseTick()
            }
        }
    }
    
    func endScanning(safetyScore: Int?, success: Bool, playHaptics: Bool = true) {
        scanTickTask?.cancel()
        scanTickTask = nil
        isAnalyzing = false
        
        guard success else {
            if playHaptics { AuraHaptics.importFailed() }
            return
        }
        
        let score = safetyScore ?? 0
        let isGood = score >= 80
        scanBurst = isGood ? .safe : .warning
        if playHaptics {
            if isGood {
                AuraHaptics.scanCompletedSuccess()
            } else {
                AuraHaptics.scanCompletedWarning()
            }
        }
        
        Task { @MainActor in
            try? await Task.sleep(for: .nanoseconds(1_200_000_000))
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                scanBurst = .none
            }
        }
    }
    
    func clearCurrentDisplay(leadAuditID: UUID?) {
        guard let leadAuditID else { return }
        suppressedLeadAuditID = leadAuditID
    }
    
    func acknowledgeNewImport() {
        suppressedLeadAuditID = nil
    }
    
    /// Clears transient hero / scan UI after SwiftData history is wiped (Settings reset).
    func resetAfterHistoryWipe() {
        scanTickTask?.cancel()
        scanTickTask = nil
        suppressedLeadAuditID = nil
        isAnalyzing = false
        scanBurst = .none
    }
}
