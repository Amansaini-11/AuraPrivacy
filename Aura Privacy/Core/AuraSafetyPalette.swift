//
//  AuraSafetyPalette.swift
//  Aura Privacy
//
//  Score-band colors for mesh, gauges, and severity copy (HIG-friendly light/dark).
//

import SwiftUI

/// Root shell mesh / scan flash driven by holistic `currentScore`: green >80, yellow 40–80, red <40.
enum AuraGlobalScoreBand: Sendable {
    case red
    case yellow
    case green
    
    static func band(forCurrentScore score: Int) -> AuraGlobalScoreBand {
        switch score {
        case ...39: return .red
        case 40...80: return .yellow
        default: return .green
        }
    }
    
    var flashColor: Color {
        switch self {
        case .red: return Color(red: 1, green: 0.25, blue: 0.28)
        case .yellow: return Color(red: 1, green: 0.72, blue: 0.12)
        case .green: return Color(red: 0.2, green: 0.92, blue: 0.55)
        }
    }
}

enum AuraSafetyBand: Int, CaseIterable, Sendable {
    case critical
    case moderate
    case good
    
    static func band(forSafetyScore score: Int) -> AuraSafetyBand {
        switch score {
        case ..<60: return .critical
        case 60...80: return .moderate
        default: return .good
        }
    }
    
    var severityTitle: String {
        switch self {
        case .critical: return "Critical"
        case .moderate: return "Moderate"
        case .good: return "Good"
        }
    }
}

enum AuraSafetyPalette {
    
    /// Nine mesh colors for `MeshGradient` (dark: saturated; light: pale pastels).
    static func meshColors(safetyScore: Int, colorScheme: ColorScheme) -> [Color] {
        let band = AuraSafetyBand.band(forSafetyScore: safetyScore)
        let isLight = colorScheme == .light
        
        switch band {
        case .critical:
            if isLight {
                return meshNine(
                    a: (0.98, 0.82, 0.82, 0.22), b: (1, 0.88, 0.78, 0.2), c: (0.98, 0.78, 0.88, 0.18),
                    d: (1, 0.85, 0.75, 0.16), e: (0.95, 0.9, 0.92, 0.35), f: (0.98, 0.8, 0.82, 0.14),
                    g: (0.96, 0.82, 0.9, 0.15), h: (1, 0.82, 0.78, 0.18), i: (0.98, 0.75, 0.82, 0.16)
                )
            }
            return meshNine(
                a: (0.95, 0.2, 0.25, 0.75), b: (1, 0.45, 0.2, 0.65), c: (0.9, 0.15, 0.4, 0.55),
                d: (1, 0.25, 0.35, 0.6), e: (0.55, 0.08, 0.12, 0.45), f: (0.95, 0.35, 0.55, 0.5),
                g: (0.85, 0.2, 0.45, 0.55), h: (1, 0.3, 0.5, 0.45), i: (0.75, 0.1, 0.25, 0.55)
            )
            
        case .moderate:
            if isLight {
                return meshNine(
                    a: (1, 0.95, 0.78, 0.22), b: (0.95, 0.98, 0.82, 0.2), c: (0.92, 0.96, 0.88, 0.22),
                    d: (1, 0.92, 0.75, 0.18), e: (0.98, 0.98, 0.95, 0.38), f: (0.9, 0.95, 0.82, 0.18),
                    g: (0.95, 0.9, 0.78, 0.16), h: (0.88, 0.96, 0.9, 0.2), i: (1, 0.88, 0.72, 0.15)
                )
            }
            return meshNine(
                a: (0.95, 0.75, 0.15, 0.55), b: (0.98, 0.55, 0.12, 0.5), c: (0.85, 0.8, 0.2, 0.45),
                d: (1, 0.65, 0.2, 0.55), e: (0.35, 0.28, 0.08, 0.35), f: (0.75, 0.85, 0.25, 0.45),
                g: (0.9, 0.5, 0.15, 0.5), h: (0.55, 0.75, 0.35, 0.4), i: (0.95, 0.45, 0.2, 0.48)
            )
            
        case .good:
            if isLight {
                return meshNine(
                    a: (0.82, 0.96, 0.9, 0.22), b: (0.78, 0.94, 0.98, 0.2), c: (0.85, 0.98, 0.92, 0.2),
                    d: (0.75, 0.92, 0.95, 0.18), e: (0.95, 0.98, 0.98, 0.4), f: (0.8, 0.95, 0.88, 0.2),
                    g: (0.72, 0.92, 0.9, 0.18), h: (0.78, 0.96, 0.94, 0.22), i: (0.7, 0.9, 0.92, 0.16)
                )
            }
            return meshNine(
                a: (0.15, 0.75, 0.55, 0.55), b: (0.2, 0.9, 0.75, 0.5), c: (0.1, 0.65, 0.85, 0.5),
                d: (0.25, 0.85, 0.7, 0.45), e: (0.05, 0.2, 0.18, 0.4), f: (0.15, 0.55, 0.75, 0.45),
                g: (0.2, 0.7, 0.6, 0.5), h: (0.3, 0.85, 0.9, 0.45), i: (0.1, 0.5, 0.55, 0.5)
            )
        }
    }
    
    /// Primary stroke colors for circular safety gauge.
    static func gaugeGradient(safetyScore: Int, colorScheme: ColorScheme) -> [Color] {
        let band = AuraSafetyBand.band(forSafetyScore: safetyScore)
        let light = colorScheme == .light
        switch band {
        case .critical:
            return light
            ? [Color(red: 0.85, green: 0.2, blue: 0.22), Color(red: 1, green: 0.45, blue: 0.35)]
            : [Color(red: 1, green: 0.25, blue: 0.3), Color(red: 1, green: 0.55, blue: 0.2)]
        case .moderate:
            return light
            ? [Color(red: 0.95, green: 0.65, blue: 0.15), Color(red: 0.5, green: 0.8, blue: 0.35)]
            : [Color(red: 1, green: 0.75, blue: 0.15), Color(red: 0.75, green: 0.85, blue: 0.2)]
        case .good:
            return light
            ? [Color(red: 0.2, green: 0.72, blue: 0.55), Color(red: 0.15, green: 0.55, blue: 0.85)]
            : [Color(red: 0.2, green: 0.95, blue: 0.65), Color(red: 0.2, green: 0.75, blue: 0.95)]
        }
    }
    
    static func severityColor(safetyScore: Int, colorScheme: ColorScheme) -> Color {
        let band = AuraSafetyBand.band(forSafetyScore: safetyScore)
        let light = colorScheme == .light
        switch band {
        case .critical:
            return light ? Color(red: 0.75, green: 0.12, blue: 0.15) : Color(red: 1, green: 0.35, blue: 0.38)
        case .moderate:
            return light ? Color(red: 0.75, green: 0.45, blue: 0.05) : Color(red: 1, green: 0.72, blue: 0.2)
        case .good:
            return light ? Color(red: 0.05, green: 0.55, blue: 0.38) : Color(red: 0.35, green: 0.95, blue: 0.75)
        }
    }
    
    /// Root `ZStack` background: red (<40), yellow (40–80), green (>80).
    static func meshColorsForGlobalCurrentScore(score: Int, colorScheme: ColorScheme) -> [Color] {
        let band = AuraGlobalScoreBand.band(forCurrentScore: score)
        let isLight = colorScheme == .light
        
        switch band {
        case .red:
            if isLight {
                return meshNine(
                    a: (0.98, 0.82, 0.82, 0.22), b: (1, 0.88, 0.78, 0.2), c: (0.98, 0.78, 0.88, 0.18),
                    d: (1, 0.85, 0.75, 0.16), e: (0.95, 0.9, 0.92, 0.35), f: (0.98, 0.8, 0.82, 0.14),
                    g: (0.96, 0.82, 0.9, 0.15), h: (1, 0.82, 0.78, 0.18), i: (0.98, 0.75, 0.82, 0.16)
                )
            }
            return meshNine(
                a: (0.95, 0.2, 0.25, 0.75), b: (1, 0.45, 0.2, 0.65), c: (0.9, 0.15, 0.4, 0.55),
                d: (1, 0.25, 0.35, 0.6), e: (0.55, 0.08, 0.12, 0.45), f: (0.95, 0.35, 0.55, 0.5),
                g: (0.85, 0.2, 0.45, 0.55), h: (1, 0.3, 0.5, 0.45), i: (0.75, 0.1, 0.25, 0.55)
            )
            
        case .yellow:
            if isLight {
                return meshNine(
                    a: (1, 0.95, 0.78, 0.22), b: (0.95, 0.98, 0.82, 0.2), c: (0.92, 0.96, 0.88, 0.22),
                    d: (1, 0.92, 0.75, 0.18), e: (0.98, 0.98, 0.95, 0.38), f: (0.9, 0.95, 0.82, 0.18),
                    g: (0.95, 0.9, 0.78, 0.16), h: (0.88, 0.96, 0.9, 0.2), i: (1, 0.88, 0.72, 0.15)
                )
            }
            return meshNine(
                a: (0.95, 0.75, 0.15, 0.55), b: (0.98, 0.55, 0.12, 0.5), c: (0.85, 0.8, 0.2, 0.45),
                d: (1, 0.65, 0.2, 0.55), e: (0.35, 0.28, 0.08, 0.35), f: (0.75, 0.85, 0.25, 0.45),
                g: (0.9, 0.5, 0.15, 0.5), h: (0.55, 0.75, 0.35, 0.4), i: (0.95, 0.45, 0.2, 0.48)
            )
            
        case .green:
            if isLight {
                return meshNine(
                    a: (0.82, 0.96, 0.9, 0.22), b: (0.78, 0.94, 0.98, 0.2), c: (0.85, 0.98, 0.92, 0.2),
                    d: (0.75, 0.92, 0.95, 0.18), e: (0.95, 0.98, 0.98, 0.4), f: (0.8, 0.95, 0.88, 0.2),
                    g: (0.72, 0.92, 0.9, 0.18), h: (0.78, 0.96, 0.94, 0.22), i: (0.7, 0.9, 0.92, 0.16)
                )
            }
            return meshNine(
                a: (0.15, 0.75, 0.55, 0.55), b: (0.2, 0.9, 0.75, 0.5), c: (0.1, 0.65, 0.85, 0.5),
                d: (0.25, 0.85, 0.7, 0.45), e: (0.05, 0.2, 0.18, 0.4), f: (0.15, 0.55, 0.75, 0.45),
                g: (0.2, 0.7, 0.6, 0.5), h: (0.3, 0.85, 0.9, 0.45), i: (0.1, 0.5, 0.55, 0.5)
            )
        }
    }
    
    private static func meshNine(
        a: (Double, Double, Double, Double),
        b: (Double, Double, Double, Double),
        c: (Double, Double, Double, Double),
        d: (Double, Double, Double, Double),
        e: (Double, Double, Double, Double),
        f: (Double, Double, Double, Double),
        g: (Double, Double, Double, Double),
        h: (Double, Double, Double, Double),
        i: (Double, Double, Double, Double)
    ) -> [Color] {
        [col(a), col(b), col(c), col(d), col(e), col(f), col(g), col(h), col(i)]
    }
    
    private static func col(_ t: (Double, Double, Double, Double)) -> Color {
        Color(red: t.0, green: t.1, blue: t.2).opacity(t.3)
    }
}
