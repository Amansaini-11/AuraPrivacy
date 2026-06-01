//
//  AuraButton.swift
//  Aura Privacy
//
//  Primary capsule control with optional shimmer for highlighted actions.
//

import SwiftUI

struct AuraButton: View {
    enum Style {
        case primary
        case subtle
    }
    
    let title: LocalizedStringKey
    let systemImage: String?
    let style: Style
    let action: () -> Void
    
    init(
        _ title: LocalizedStringKey,
        systemImage: String? = nil,
        style: Style = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .imageScale(.medium)
                }
                Text(title)
                    .font(.headline.weight(.semibold))
                    .dynamicTypeSize(.medium ... .accessibility3)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(background)
            .foregroundStyle(foreground)
            .clipShape(Capsule(style: .continuous))
            .overlay {
                if style == .primary {
                    Capsule(style: .continuous)
                        .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                }
            }
            .modifier(AuraShimmerModifier(isActive: style == .primary))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
    }
    
    @ViewBuilder private var background: some View {
        switch style {
        case .primary:
            LinearGradient(
                colors: [
                    Color(red: 0.31, green: 0.84, blue: 0.67),
                    Color(red: 0.14, green: 0.52, blue: 0.92),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .subtle:
            Color.white.opacity(0.08)
        }
    }
    
    private var foreground: Color {
        switch style {
        case .primary:
            return Color.white
        case .subtle:
            return Color.primary
        }
    }
}
