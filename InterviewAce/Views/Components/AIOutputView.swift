//
//  MainBox.swift
//  InterviewAce
//
//  Created by kartikay on 01/05/25.
//


import SwiftUI

/// Main content box shown in the left column below the Siri voice bar
struct AIOutputView: View {
    @EnvironmentObject var aiViewModel: AIViewModel
    
    var body: some View {
        // Use a ZStack to layer the content
        ZStack {
            // Use the GlassBox component as the background
            GlassBox(title: "", height: 500)
            
            VStack(alignment: .leading, spacing: 12) {
                // Title area
                HStack {
                    Text("Gemini 2.0 Flash")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Show loading indicator when processing
                    if case .processing = aiViewModel.state {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                }
                .padding(.bottom, 4)
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                // Content area - shows response or appropriate message
                ScrollView {
                    responseContent
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
            }
            .padding(20)
        }
    }
    
    @ViewBuilder
    private var responseContent: some View {
        switch aiViewModel.state {
        case .idle:
            Text("Ask a question or speak to get an AI response")
                .foregroundColor(.white.opacity(0.6))
                .italic()
                .font(.system(size: 16))
        case .processing:
            VStack(alignment: .leading, spacing: 16) {
                Text("Processing request...")
                    .foregroundColor(.white.opacity(0.7))
                    .italic()
                    .font(.system(size: 16))
            }
        case .success(let response):
            // Use the markdown renderer
            MarkdownText(text: response, fontSize: 16, textColor: .white.opacity(0.9))
                .foregroundColor(.white.opacity(0.9))
                .font(.system(size: 16))
        case .error(let errorMessage):
            VStack(alignment: .leading, spacing: 8) {
                Text("Error")
                    .font(.headline)
                    .foregroundColor(.red)
                Text(errorMessage)
                    .foregroundColor(.white.opacity(0.8))
                    .font(.system(size: 16))
            }
        }
    }
}

#Preview {
    AIOutputView()
        .environmentObject(AIViewModel())
        .frame(width: 500, height: 500)
        .background(Color.black)
}

