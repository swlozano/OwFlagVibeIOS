//
//  Item.swift
//  OwFlagVideCode
//
//  Created by The Main Fun on 25/08/25.
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
