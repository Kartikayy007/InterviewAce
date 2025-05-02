//
//  MinimizeViewModel.swift
//  InterviewAce
//
//  Created by kartikay on 02/05/25.
//

import Foundation
import SwiftUI

// Define notification name for minimize toggle
extension Notification.Name {
    static let minimizeStateChanged = Notification.Name("MinimizeStateChanged")
}

class MinimizeViewModel: ObservableObject {
    @Published var isMinimized: Bool = false

    func toggle() {
        isMinimized.toggle()
        print("minimized: \(isMinimized)")
        
        // Post notification that minimize state changed
        NotificationCenter.default.post(
            name: .minimizeStateChanged,
            object: nil,
            userInfo: ["isMinimized": isMinimized]
        )
    }
}
