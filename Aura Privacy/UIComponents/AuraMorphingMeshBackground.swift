//
//  AuraMorphingMeshBackground.swift
//  Aura Privacy
//
//  Full-screen slowly morphing MeshGradient driven by safety score band + color scheme.
//

import SwiftUI

struct AuraMorphingMeshBackground: View {
    let safetyScore: Int
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: false)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let wobble = sin(t * 0.35) * 0.04
            let wobble2 = cos(t * 0.28) * 0.035
            
            let pts: [SIMD2<Float>] = [
                .init(0, 0),
                .init(Float(0.5 + wobble2), 0),
                .init(1, 0),
                .init(0, Float(0.45 + wobble)),
                .init(Float(0.55 + wobble2 * 0.6), Float(0.5 + wobble * 0.8)),
                .init(1, Float(0.55 - wobble)),
                .init(0, 1),
                .init(Float(0.45 - wobble2), 1),
                .init(1, 1),
            ]
            
            let colors = AuraSafetyPalette.meshColors(safetyScore: safetyScore, colorScheme: colorScheme)
            
            MeshGradient(width: 3, height: 3, points: pts, colors: colors)
        }
        .ignoresSafeArea()
    }
}
