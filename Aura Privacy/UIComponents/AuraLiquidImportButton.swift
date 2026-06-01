//
//  AuraLiquidImportButton.swift
//  Aura Privacy
//
//  Promenade-blue primary import control with liquid shine on press.
//

import SwiftUI

struct AuraLiquidImportButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.title3.weight(.semibold))
                Text("Import Privacy Report")
                    .font(.system(.headline, design: .rounded).weight(.bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
        .buttonStyle(AuraLiquidImportButtonStyle())
    }
}

private struct AuraLiquidImportButtonStyle: ButtonStyle {
    private let promenadeBlue = Color(red: 0.22, green: 0.48, blue: 0.92)
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [promenadeBlue, promenadeBlue.opacity(0.82)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    if configuration.isPressed {
                        LinearGradient(
                            colors: [
                                .white.opacity(0.65),
                                .white.opacity(0.08),
                                .white.opacity(0.55),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .blendMode(.screen)
                        .transition(.opacity)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(.white.opacity(0.38), lineWidth: 1)
                }
                .modifier(CompatibleLiquidGlass(cornerRadius: 22))
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.34, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

private struct CompatibleLiquidGlass: ViewModifier {
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            content
        }
    }
}
