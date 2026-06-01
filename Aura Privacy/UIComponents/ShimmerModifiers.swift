//
//  ShimmerModifiers.swift
//  Aura Privacy
//
//  Lightweight shimmer overlay used by hero buttons and badges.
//

import SwiftUI

struct AuraShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = -1
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive {
                    GeometryReader { proxy in
                        LinearGradient(
                            colors: [
                                .white.opacity(0.05),
                                .white.opacity(0.55),
                                .white.opacity(0.05),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .rotationEffect(.degrees(12))
                        .offset(x: phase * proxy.size.width * 1.8)
                        .blendMode(.screen)
                        .mask(content)
                    }
                    .allowsHitTesting(false)
                    .onAppear {
                        withAnimation(.linear(duration: 2.6).repeatForever(autoreverses: false)) {
                            phase = 1
                        }
                    }
                }
            }
    }
}
