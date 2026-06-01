//
//  FullScreenScannerOverlay.swift
//  Aura Privacy
//
//  Layer-4 full-screen import experience: radar, copy, completion flash.
//

import SwiftUI


struct FullScreenScannerOverlay: View {
    @Bindable var coordinator: ShellScanCoordinator
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()
            
            if let band = coordinator.flashBand {
                band.flashColor
                    .opacity(coordinator.flashOpacity * 0.55)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            
            VStack(spacing: 28) {
                RadarPulseView()
                    .frame(width: 220, height: 220)
                
                Text("Analyzing data packets locally…")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .transition(.opacity)
    }
}

private struct RadarPulseView: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<5, id: \.self) { i in
                    let phase = t * 1.4 + Double(i) * 0.55
                    let scale = 0.45 + 0.12 * CGFloat(i) + 0.08 * sin(phase)
                    let opacity = 0.55 - Double(i) * 0.09
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color.cyan.opacity(0.9),
                                    Color.blue.opacity(0.5),
                                    Color.mint.opacity(0.85),
                                    Color.cyan.opacity(0.9),
                                ],
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 160 + CGFloat(i) * 36, height: 160 + CGFloat(i) * 36)
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .rotationEffect(.degrees(t * 40 + Double(i * 12)))
                }
                
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.cyan.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .cyan.opacity(0.9), radius: 24)
            }
        }
    }
}



