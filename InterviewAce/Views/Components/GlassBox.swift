//
//  GlassBox.swift
//  InterviewAce
//
//  Created by kartikay on 01/05/25.
//


import SwiftUI

/// A reusable glass-like box component used throughout the interface
struct GlassBox: View {
    // Properties that can be customized when creating an instance
    var title: String        // Text to display inside the box
    var height: CGFloat?     // Optional height - if nil, view will size to content
    
    var body: some View {
        ZStack {
            // Creates the glass-like appearance
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.3), lineWidth: 2)  // Adds a subtle border
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial.opacity(0.1))   // Translucent material for glass effect
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))   // Clips the content to rounded corners
                .shadow(color: Color.white.opacity(0.1), radius: 10, x: 0, y: 5)  // Adds a subtle glow
            
            // Text displayed inside the box
            Text(title)
                .font(.custom("SF Pro Rounded", size: 20, relativeTo: .title3))  // Custom font
                .foregroundColor(.white)  // Text color
        }
        // Apply height if provided, otherwise size to content
        .frame(height: height)
    }
}