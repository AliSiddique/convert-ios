//
//  Item.swift
//  jpg-conv
//
//  Created by Ali Siddique on 1/11/25.
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
