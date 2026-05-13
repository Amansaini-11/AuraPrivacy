//
//  Item.swift
//  Aura Privacy
//
//  Created by Aman on 13/05/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
