//
//  AuraPrivacyScoreGauge.swift
//  Aura Privacy
//
//  Large circular safety score dial with dynamic stroke gradient.
//

import SwiftUI

struct AuraPrivacyScoreGauge: View {
    let score: Int
    let lineWidth: CGFloat
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var progress: CGFloat {
        CGFloat(max(0, min(100, score))) / 100.0
    }
    
    private var strokeColors: [Color] {
        let g = AuraSafetyPalette.gaugeGradient(safetyScore: score, colorScheme: colorScheme)
        if let first = g.first {
            return g + [first]
        }
        return g
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(colorScheme == .light ? 0.12 : 0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: strokeColors,
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 6) {
                Text("\(score)")
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                
                Text(AuraSafetyBand.band(forSafetyScore: score).severityTitle)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(AuraSafetyPalette.severityColor(safetyScore: score, colorScheme: colorScheme))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Safety score \(score), \(AuraSafetyBand.band(forSafetyScore: score).severityTitle)")
    }
}
