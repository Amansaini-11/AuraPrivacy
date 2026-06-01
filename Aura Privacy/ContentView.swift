//
//  ContentView.swift
//  Aura Privacy
//
//  Root shell: onboarding, splash, theme preference, and main dashboard.
//

import SwiftData
import SwiftUI
import LocalAuthentication

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("appTheme") private var appThemeRaw = AppThemePreference.system.rawValue
    @AppStorage("requireFaceID") private var requireFaceID = false
    
    @State private var splashComplete = false
    @State private var didBootstrapLaunchFlow = false
    @State private var appShellState = AppShellState()
    @State private var viewModel = AuraViewModel()
    @State private var shellScanCoordinator = ShellScanCoordinator()
    @State private var isUnlocked = false
    @State private var isAuthenticating = false
    @Environment(\.scenePhase) private var scenePhase
    
    private var theme: AppThemePreference {
        AppThemePreference(rawValue: appThemeRaw) ?? .system
    }
    
    var body: some View {
        Group {
            if hasSeenOnboarding == false {
                OnboardingView()
            } else if splashComplete == false {
                LaunchScreenView {
                    splashComplete = true
                }
            } else {
                MainTabShellView()
                    .environment(appShellState)
                    .environment(viewModel)
                    .environment(shellScanCoordinator)
            }
        }
        .preferredColorScheme(theme.colorScheme)
        .overlay {
            if requireFaceID && isUnlocked == false && hasSeenOnboarding && splashComplete {
                ZStack {
                    Color.black.opacity(0.92).ignoresSafeArea()
                    VStack(spacing: 14) {
                        Image(systemName: "faceid")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("Unlock Aura Privacy")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                        Button("Use Face ID") {
                            authenticateIfRequired()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: hasSeenOnboarding)
        .animation(.easeInOut(duration: 0.35), value: splashComplete)
        .onAppear {
            guard didBootstrapLaunchFlow == false else { return }
            didBootstrapLaunchFlow = true
            if hasSeenOnboarding == false {
                splashComplete = true
            }
        }
        .onChange(of: hasSeenOnboarding) { _, newValue in
            if newValue {
                splashComplete = true
            }
        }
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .background || newValue == .inactive {
                if requireFaceID && isAuthenticating == false {
                    isUnlocked = false
                }
                return
            }
            guard newValue == .active else { return }
            if requireFaceID {
                if isUnlocked == false {
                    authenticateIfRequired()
                }
            } else {
                isUnlocked = true
            }
        }
        .task {
            if requireFaceID {
                authenticateIfRequired()
            } else {
                isUnlocked = true
            }
        }
    }
    
    private func authenticateIfRequired() {
        guard requireFaceID else {
            isUnlocked = true
            return
        }
        guard isAuthenticating == false else { return }
        isAuthenticating = true
        
        let context = LAContext()
        var error: NSError?
        let policy: LAPolicy = .deviceOwnerAuthentication
        guard context.canEvaluatePolicy(policy, error: &error) else {
            isUnlocked = true
            isAuthenticating = false
            return
        }
        context.evaluatePolicy(policy, localizedReason: "Unlock your privacy dashboard") { success, _ in
            DispatchQueue.main.async {
                isUnlocked = success
                isAuthenticating = false
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [PrivacyAudit.self, AppRiskProfile.self], inMemory: true)
        .environment(SubscriptionManager())
        .environment(AppShellState())
        .environment(AuraViewModel())
        .environment(ShellScanCoordinator())
}
