//
//  AuraTappableGlassCard.swift
//  Aura Privacy
//
//  Liquid Glass cards; use with `Button` / `NavigationLink` for tactile feedback.
//

import SwiftUI

struct AuraTappableGlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 24
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        content()
            .padding(12)
            .background {
                if #available(iOS 26.0, *) {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.clear)
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
