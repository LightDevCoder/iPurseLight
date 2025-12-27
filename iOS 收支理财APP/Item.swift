//
//  Item.swift
//  iOS 收支理财APP
//
//  Created by Light Chan on 27/12/2025.
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
