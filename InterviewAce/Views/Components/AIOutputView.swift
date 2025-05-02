//
//  MainBox.swift
//  InterviewAce
//
//  Created by kartikay on 01/05/25.
//


import SwiftUI

/// Main content box shown in the left column below the Siri voice bar
struct AIOutputView: View {
    var body: some View {
        // Use the GlassBox component with custom height
        // This is the large box on the left side
        GlassBox(title: "Main box", height: 500)
    }
}

