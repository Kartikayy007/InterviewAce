//
//  SecondaryBox.swift
//  InterviewAce
//
//  Created by kartikay on 01/05/25.
//


import SwiftUI

struct OutputCodeView: View {
    var body: some View {
        // Use the GlassBox component with custom height
        // This is the top box in the right column
        GlassBox(title: "Secondary box", height: 400)
    }
}

// Preview provider to see this component in isolation
#Preview {
    ContentView()
}
