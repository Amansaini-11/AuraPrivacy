import SwiftUI

enum AuraRebuildTheme {
    static let backgroundBase = Color(hex: "#0E1024")
    static let foreground = Color(hex: "#F7F7FA")
    static let muted = Color(hex: "#A8ADC2")
    static let success = Color(hex: "#3DDC97")
    static let warning = Color(hex: "#F5B642")
    static let danger = Color(hex: "#F2553B")
}

enum AuraScoreTone {
    case low
    case moderate
    case high
    
    var a: Color {
        switch self {
        case .low: return Color(hex: "#3DDC97")
        case .moderate: return Color(hex: "#F5B642")
        case .high: return Color(hex: "#F2553B")
        }
    }
    
    var b: Color {
        switch self {
        case .low: return Color(hex: "#34C5AE")
        case .moderate: return Color(hex: "#F39024")
        case .high: return Color(hex: "#F39024")
        }
    }
}

func auraTone(for score: Int) -> AuraScoreTone {
    if score >= 70 { return .low }
    if score >= 45 { return .moderate }
    return .high
}

func auraScoreLabel(_ score: Int) -> String {
    switch auraTone(for: score) {
    case .low: return "Excellent"
    case .moderate: return "Fair"
    case .high: return "At Risk"
    }
}

struct AuraAmbientBackground: View {
    let score: Int
    private var blobColor: Color {
        switch auraTone(for: score) {
        case .low: return Color(hex: "#25F9C1")
        case .moderate: return Color(hex: "#FFC14F")
        case .high: return Color(hex: "#FF5A5A")
        }
    }
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 18.0, paused: false)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let driftX = CGFloat(sin(t * 0.1)) * 14
            let driftY = CGFloat(cos(t * 0.08)) * 10
            
            ZStack {
                Color(hex: "#1A1616")
                    .ignoresSafeArea()
                
                // Focused score aura blob (center-top where the dial lives).
                Ellipse()
                    .fill(blobColor.opacity(0.62))
                    .frame(width: 330, height: 290)
                    .blur(radius: 86)
                    .offset(x: driftX, y: -220 + driftY)
                
                // Secondary blend blob to add premium depth around the score region.
                Ellipse()
                    .fill(blobColor.opacity(0.36))
                    .frame(width: 270, height: 230)
                    .blur(radius: 92)
                    .offset(x: -36 - driftX * 0.5, y: -150 - driftY * 0.6)
                
                // Very subtle bottom tint so lower content doesn't feel flat.
                Ellipse()
                    .fill(blobColor.opacity(0.16))
                    .frame(width: 420, height: 260)
                    .blur(radius: 98)
                    .offset(x: 0, y: 360)
            }
        }
    }
}

struct AuraGlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 20
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        content()
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .background(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(.white.opacity(0.04)))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 1)
            }
    }
}

struct AuraScoreRing: View {
    let score: Int
    let size: CGFloat
    let lineWidth: CGFloat
    @State private var animatedScore: CGFloat = 0
    @State private var glowScale = false
    
    private var progress: CGFloat {
        CGFloat(max(0, min(score, 100))) / 100
    }
    
    var body: some View {
        let tone = auraTone(for: score)
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [tone.a.opacity(0.48), .clear], center: .center, startRadius: 10, endRadius: size * 0.65))
                .scaleEffect(glowScale ? 1.08 : 1.0)
                .opacity(glowScale ? 0.7 : 0.4)
            
            Circle()
                .stroke(.white.opacity(0.08), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: animatedScore)
                .stroke(
                    LinearGradient(colors: [tone.a, tone.b], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 8) {
                Text("PRIVACY SCORE")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2.5)
                    .foregroundStyle(AuraRebuildTheme.muted)
                Text("\(score)")
                    .font(.system(size: 72, weight: .semibold, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: [tone.a, tone.b], startPoint: .topLeading, endPoint: .bottomTrailing))
                Text(auraScoreLabel(score))
                    .font(.system(size: 30/2, weight: .medium))
                    .foregroundStyle(tone.a)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 1.6)) {
                animatedScore = progress
            }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                glowScale.toggle()
            }
        }
        .onChange(of: score) { _, new in
            withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 1.6)) {
                animatedScore = CGFloat(max(0, min(new, 100))) / 100
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
