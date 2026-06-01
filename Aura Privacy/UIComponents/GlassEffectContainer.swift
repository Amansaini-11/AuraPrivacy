//
//  GlassEffectContainer.swift
//  Aura Privacy
//
//  Reusable Liquid Glass wrapper tuned for dashboard cards.
//

import SwiftUI

/// Applies the system Liquid Glass material within a continuous rounded rectangle.
struct GlassEffectContainer<Content: View>: View {
    var cornerRadius: CGFloat = 28
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        content()
            .padding(12)
            .background {
                if #available(iOS 26.0, *) {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                        }
                }
            }
    }
}
