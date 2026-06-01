//
//  AuraInteractiveButtonStyle.swift
//  Aura Privacy
//
//  Shared press feedback for controls that sit on glass or mesh backdrops.
//

import SwiftUI

/// High-readability control treatment used where a full `AuraButton` capsule is too heavy.
struct AuraInteractiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.88 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

extension View {
    /// Applies the standard Aura interactive press treatment (use with `GlassEffectContainer` labels).
    func auraInteractive() -> some View {
        buttonStyle(AuraInteractiveButtonStyle())
    }
}
