//
//  LaunchScreenView.swift
//  Aura Privacy
//
//  Brief branded splash shown on cold start after onboarding has completed.
//

import SwiftUI

struct LaunchScreenView: View {
    let onFinished: () -> Void
    
    @State private var glow = false
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.mint.opacity(glow ? 0.55 : 0.2),
                                    Color.cyan.opacity(glow ? 0.25 : 0.08),
                                    .clear,
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 160
                            )
                        )
                        .frame(width: 300, height: 200)
                        .blur(radius: 50)
                    
                    Image("AuraBrandIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 118, height: 118)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                        }
                }
                
                Text("Aura Privacy")
                    .fontDesign(.monospaced)
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                glow = true
            }
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                await MainActor.run {
                    onFinished()
                }
            }
        }
    }
}

