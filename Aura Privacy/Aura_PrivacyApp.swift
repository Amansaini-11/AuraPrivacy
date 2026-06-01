//
//  Aura_PrivacyApp.swift
//  Aura Privacy
//
//  Application entry — wires SwiftData, subscriptions, and navigation shell state.
//

import SwiftData
import SwiftUI

@main
struct Aura_PrivacyApp: App {
    @State private var subscriptions = SubscriptionManager()
    
    private var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PrivacyAudit.self,
            AppRiskProfile.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("SwiftData container unavailable: \(error.localizedDescription)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(subscriptions)
                .task {
                    subscriptions.configureIfNeeded()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
