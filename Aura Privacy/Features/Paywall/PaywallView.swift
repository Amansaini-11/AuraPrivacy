//
//  PaywallView.swift
//  Aura Privacy
//

import RevenueCat
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var subscriptions
    
    @State private var purchaseError: String?
    @State private var isPurchasing = false
    @State private var selectedPackage: Package?
    @State private var continueGlow = false
    
    var body: some View {
        ZStack {
            AuraAmbientBackground(score: 58)
            ScrollView {
                VStack(spacing: 24) {
                    Capsule()
                        .fill(LinearGradient(colors: [Color(hex: "#F5C758"), Color(hex: "#E89B3C")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 74, height: 10)
                        .padding(.top, 6)
                    
                    Text("Aura Privacy ")
                        .font(.system(size: 44/1.7, weight: .bold))
                        .foregroundStyle(AuraRebuildTheme.foreground)
                    + Text("Pro")
                        .font(.system(size: 44/1.7, weight: .bold))
                        .foregroundStyle(LinearGradient(colors: [Color(hex: "#F5C758"), Color(hex: "#E89B3C")], startPoint: .topLeading, endPoint: .bottomTrailing))
                    
                    Text("Stop trackers before they even reach you.\nBuilt for people who take privacy seriously.")
                        .font(.system(size: 15))
                        .foregroundStyle(AuraRebuildTheme.muted)
                        .multilineTextAlignment(.center)
                    
                    ForEach(Array(featureRows.enumerated()), id: \.offset) { _, row in
                        AuraGlassCard(cornerRadius: 22) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color(hex: "#F5B642").opacity(0.24))
                                    .frame(width: 40, height: 40)
                                    .overlay { Image(systemName: row.icon).foregroundStyle(Color(hex: "#F5B642")) }
                                Text(row.title)
                                    .font(.system(size: 28/2, weight: .medium))
                                    .foregroundStyle(AuraRebuildTheme.foreground)
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AuraRebuildTheme.success)
                            }
                        }
                    }
                    
                    planRow
                    continueButton
                    
                    Text("Cancel anytime · Secured by App Store")
                        .font(.system(size: 12))
                        .foregroundStyle(AuraRebuildTheme.muted)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert("Purchase issue", isPresented: Binding(
            get: { purchaseError != nil },
            set: { if !$0 { purchaseError = nil } })
        ) {
            Button("OK", role: .cancel) { purchaseError = nil }
        } message: {
            Text(purchaseError ?? "")
        }
        .task {
            await subscriptions.refresh()
            syncDefaultSelection()
        }
    }
    
    private var featureRows: [(icon: String, title: String)] {
        [
            ("shield", "Real-time tracker blocking"),
            ("bolt", "Deep weekly scans"),
            ("bell", "Instant high-risk alerts"),
            ("eye", "Hidden permission monitor"),
            ("sparkles", "Priority support & updates")
        ]
    }
    
    private var planRow: some View {
        VStack(spacing: 12) {
            if let annual = package(for: .annual) {
                planCard(package: annual, title: "YEARLY", badge: "Save 60%", selected: selectedPackage?.identifier == annual.identifier)
            }
            if let monthly = package(for: .monthly) {
                planCard(package: monthly, title: "MONTHLY", badge: nil, selected: selectedPackage?.identifier == monthly.identifier)
            }
            if let lifetime = package(for: .lifetime) {
                planCard(package: lifetime, title: "LIFETIME", badge: "Best value", selected: selectedPackage?.identifier == lifetime.identifier)
            }
        }
    }
    
    private func planCard(package: Package, title: String, badge: String?, selected: Bool) -> some View {
        Button {
            selectedPackage = package
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(1.4)
                        .foregroundStyle(AuraRebuildTheme.muted)
                    Spacer()
                    if let badge {
                        Text(badge)
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(hex: "#F39024"), in: Capsule())
                            .foregroundStyle(.black)
                    }
                }
                Text(package.storeProduct.localizedPriceString)
                    .font(.system(size: 38/1.5, weight: .semibold))
                    .foregroundStyle(AuraRebuildTheme.foreground)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(selected ? Color(hex: "#F5B642") : .white.opacity(0.1), lineWidth: selected ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var continueButton: some View {
        Button {
            guard let selectedPackage else { return }
            Task { await purchase(selectedPackage) }
        } label: {
            Text("Continue · \(selectedPackage?.storeProduct.localizedPriceString ?? "")")
                .font(.system(size: 30/1.7, weight: .bold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: [Color(hex: "#F5C758"), Color(hex: "#F39024")], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: Capsule()
                )
                .shadow(color: Color(hex: "#F5C758").opacity(continueGlow ? 0.45 : 0.18), radius: continueGlow ? 18 : 8, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(selectedPackage == nil || isPurchasing)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                continueGlow.toggle()
            }
        }
    }
    
    private func package(for type: PackageType) -> Package? {
        let list = subscriptions.offerings?.current?.availablePackages ?? []
        if let byType = list.first(where: { $0.packageType == type }) {
            return byType
        }
        switch type {
        case .monthly:
            return list.first { $0.storeProduct.productIdentifier.localizedCaseInsensitiveContains("month") }
        case .annual:
            return list.first {
                $0.storeProduct.productIdentifier.localizedCaseInsensitiveContains("year")
                || $0.storeProduct.productIdentifier.localizedCaseInsensitiveContains("annual")
            }
        case .lifetime:
            return list.first {
                $0.packageType == .lifetime
                || $0.storeProduct.productIdentifier.localizedCaseInsensitiveContains("lifetime")
            }
        default:
            return nil
        }
    }
    
    private func syncDefaultSelection() {
        selectedPackage = package(for: .annual) ?? package(for: .monthly) ?? subscriptions.offerings?.current?.availablePackages.first
    }
    
    private func purchase(_ package: Package) async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await subscriptions.purchase(package: package)
            dismiss()
        } catch {
            purchaseError = error.localizedDescription
        }
    }
}
