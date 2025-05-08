//
//  TertiaryBox.swift
//  InterviewAce
//
//  Created by kartikay on 01/05/25.
//


import SwiftUI

/// Tertiary content box shown in the lower part of the right column
struct TertiaryBox: View {
    var body: some View {
        // Use the GlassBox component with custom height
        // This is the bottom box in the right column
        GlassBox(title: "Tertiary box", height: 180)
        VStack {
            Text("This is regular text.")
            Text("* This is **bold** text, this is *italic* text, and this is ***bold, italic*** text.")
            Text("~~A strikethrough example~~")
            Text("`Monospaced works too`")
            Text("Visit Apple: [click here](https://apple.com)")
        }

    }
}

// Preview provider to see this component in isolation
#Preview {
    TertiaryBox()
        .frame(width: 400)
        .padding()
        .background(Color.black)  // Add black background for preview
}
