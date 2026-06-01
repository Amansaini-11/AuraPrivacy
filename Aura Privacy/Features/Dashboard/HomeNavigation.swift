//
//  HomeNavigation.swift
//  Aura Privacy
//
//  Type-safe navigation values so profile routes never collide with audit history routes.
//

import Foundation

struct ProfileNavID: Hashable {
    let id: UUID
}

struct HistoricalScanNavID: Hashable {
    let auditID: UUID
}
