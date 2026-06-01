//
//  AuraRootShellBackground.swift
//  Aura Privacy
//
//  Full-screen morphing mesh for the root tab shell so the gradient runs edge-to-edge
//  behind floating chrome (no opaque tab strip).
//

import SwiftUI

struct AnimatedAuraBackground: View {
    /// Global holistic score (drives red / yellow / green root mesh).
    var currentScore: Int
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: false)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let wobble = sin(t * 0.42) * 0.055
            let wobble2 = cos(t * 0.33) * 0.048
            let breathe = 0.92 + 0.08 * sin(t * 0.5)
            
            let pts: [SIMD2<Float>] = [
                .init(0, 0),
                .init(Float(0.5 + wobble2 * 0.9), 0),
                .init(1, 0),
                .init(Float(0.02 + wobble), Float(0.42 + wobble2 * 0.5)),
                .init(Float(0.52 + wobble2 * breathe), Float(0.5 + wobble)),
                .init(1, Float(0.58 - wobble2)),
                .init(0, 1),
                .init(Float(0.48 - wobble), 1),
                .init(1, 1),
            ]
            
            let colors = AuraSafetyPalette.meshColorsForGlobalCurrentScore(score: currentScore, colorScheme: colorScheme)
            
            MeshGradient(width: 3, height: 3, points: pts, colors: colors)
        }
        .ignoresSafeArea()
    }
}

typealias AuraRootShellBackground = AnimatedAuraBackground
