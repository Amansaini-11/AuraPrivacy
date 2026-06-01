//
//  ExportCardView.swift
//  Aura Privacy
//
//  ImageRenderer-only share asset: vibrant mesh, bold score headline, QR placeholder.
//

import SwiftUI


struct ExportCardView: View {
    let audit: PrivacyAudit
    
    private var scorePercent: Int {
        max(0, min(100, audit.safetyScore))
    }
    
    var body: some View {
        ZStack {
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    .init(0, 0), .init(0.5, 0), .init(1, 0),
                    .init(0, 0.5), .init(0.55, 0.45), .init(1, 0.55),
                    .init(0, 1), .init(0.45, 1), .init(1, 1),
                ],
                colors: [
                    Color(red: 0.2, green: 0.85, blue: 0.95),
                    Color(red: 0.55, green: 0.25, blue: 0.95),
                    Color(red: 0.95, green: 0.35, blue: 0.55),
                    Color(red: 0.15, green: 0.45, blue: 0.95),
                    Color(red: 0.35, green: 0.9, blue: 0.65),
                    Color(red: 0.9, green: 0.55, blue: 0.2),
                    Color(red: 0.25, green: 0.2, blue: 0.55),
                    Color(red: 0.5, green: 0.85, blue: 1),
                    Color(red: 0.95, green: 0.2, blue: 0.45),
                ]
            )
            .opacity(0.4)
            .ignoresSafeArea()
            
            Color.black.opacity(0.55)
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                Spacer(minLength: 40)
                
                Text("My Privacy Score: \(scorePercent)%")
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 36)
                    .shadow(color: .cyan.opacity(0.45), radius: 20)
                
                Text("Verified on-device • \(audit.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                
                Spacer()
                
                qrPlaceholder
                
                Text("Aura Privacy")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                    .padding(.bottom, 40)
            }
        }
        .frame(width: 720, height: 960)
        .clipped()
    }
    
    private var qrPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.92))
                .frame(width: 140, height: 140)
            Image(systemName: "qrcode")
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(.black.opacity(0.85))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.5), lineWidth: 2)
        }
    }
    
}

