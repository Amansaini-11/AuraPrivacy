//
//  SubscriptionManager.swift
//  Aura Privacy
//
//  RevenueCat Purchases SDK wiring — supply `RevenueCatPublicAPIKey` in Info.plist.
//

import Foundation
import RevenueCat
import SwiftUI

/// Central subscription gate used by paywall + premium sharing flows.
@Observable @MainActor
final class SubscriptionManager: NSObject {
    
    /// Matches the entitlement identifier configured in RevenueCat.
    static let proEntitlementIdentifier = "pro"
    
    private static var didConfigureSDK = false
    
    private(set) var customerInfo: CustomerInfo?
    private(set) var offerings: Offerings?
    
    var isProSubscriber: Bool {
#if DEBUG
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "RevenueCatPublicAPIKey") as? String ?? ""
        if apiKey.isEmpty {
            // Lets premium flows run locally until RevenueCat is wired (release always checks entitlements below).
            return true
        }
#endif
        return customerInfo?.entitlements[Self.proEntitlementIdentifier]?.isActive == true
    }
    
    override init() {
        super.init()
    }
    
    func configureIfNeeded() {
        Purchases.logLevel = .warn
        
        guard Self.didConfigureSDK == false else {
            Task { await refresh() }
            return
        }
        
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "RevenueCatPublicAPIKey") as? String ?? "test_xRZykcQNQiygoOwtbcAdvwGyDMK"
        guard apiKey.isEmpty == false else {
#if DEBUG
            print("RevenueCatPublicAPIKey missing — subscriptions offline until configured.")
#endif
            return
        }
        
        Purchases.configure(withAPIKey: apiKey)
        Purchases.shared.delegate = self
        Self.didConfigureSDK = true
        
        Task { await refresh() }
    }
    
    func refresh() async {
        guard Self.didConfigureSDK else { return }
        do {
            async let info = Purchases.shared.customerInfo()
            async let offers = Purchases.shared.offerings()
            customerInfo = try await info
            offerings = try await offers
        } catch {
#if DEBUG
            print("RevenueCat refresh failed: \(error.localizedDescription)")
#endif
        }
    }
    
    func purchase(package: Package) async throws {
        let result = try await Purchases.shared.purchase(package: package)
        customerInfo = result.customerInfo
    }
    
    func restore() async throws {
        customerInfo = try await Purchases.shared.restorePurchases()
    }
}

extension SubscriptionManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.customerInfo = customerInfo
        }
    }
}
