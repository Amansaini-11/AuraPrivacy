//
//  OnboardingView.swift
//  Aura Privacy
//
//  First-launch three-page flow; requests notification permission on the final step.
//

import SwiftUI
import UserNotifications


struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var page = 0
    
    var body: some View {
        ZStack {
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    .init(0, 0), .init(0.5, 0), .init(1, 0),
                    .init(0, 0.5), .init(0.5, 0.5), .init(1, 0.5),
                    .init(0, 1), .init(0.5, 1), .init(1, 1),
                ],
                colors: [
                    Color.teal.opacity(0.35),
                    Color.indigo.opacity(0.4),
                    Color.cyan.opacity(0.3),
                    Color.purple.opacity(0.25),
                    Color.black.opacity(0.2),
                    Color.mint.opacity(0.3),
                    Color.blue.opacity(0.35),
                    Color.green.opacity(0.25),
                    Color.black.opacity(0.35),
                ]
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    onboardingPage(
                        tag: 0,
                        symbol: "hand.raised.fill",
                        title: "Take back your data",
                        body: "Aura Privacy reads your App Privacy Report entirely on-device. No accounts, no cloud uploads—just clarity on what your apps actually touch."
                    )
                    
                    onboardingPage(
                        tag: 1,
                        symbol: "arrow.down.doc.fill",
                        title: "How it works",
                        body: "Export your report from Settings, import it here, and get an instant safety score plus per-app risk insight powered by on-device intelligence."
                    )
                    
                    onboardingPage(
                        tag: 2,
                        symbol: "bell.badge.fill",
                        title: "Stay in the loop",
                        body: "Optional alerts can remind you to re-run a scan after major iOS updates or when you install sensitive apps."
                    )
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(.easeInOut, value: page)
                
                VStack(spacing: 14) {
                    if page < 2 {
                        AuraButton("Continue", systemImage: "arrow.right") {
                            withAnimation { page += 1 }
                        }
                    } else {
                        AuraButton("Enable reminders", systemImage: "bell.badge.fill") {
                            Task { await requestNotificationsThenFinish() }
                        }
                        
                        Button("Not now") {
                            finishOnboarding()
                        }
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
                .padding(.top, 8)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func onboardingPage(tag: Int, symbol: String, title: String, body: String) -> some View {
        GlassEffectContainer(cornerRadius: 32) {
            VStack(spacing: 22) {
                Image(systemName: symbol)
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(.tint)
                    .symbolRenderingMode(.hierarchical)
                    .padding(.top, 8)
                
                Text(title)
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .multilineTextAlignment(.center)
                
                Text(body)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .tag(tag)
    }
    
    private func requestNotificationsThenFinish() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        finishOnboarding()
    }
    
    private func finishOnboarding() {
        hasSeenOnboarding = true
    }
}
