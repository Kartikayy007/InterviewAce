//
//  SecondaryBox.swift
//  InterviewAce
//
//  Created by kartikay on 01/05/25.
//


import SwiftUI

struct OutputCodeView: View {
    @EnvironmentObject var aiViewModel: AIViewModel

    // Use computed properties to always get the latest data
    private var currentCode: String {
        return aiViewModel.selectedCodeCard?.code ?? ""
    }

    private var currentTitle: String {
        return aiViewModel.selectedCodeCard?.title ?? "Code"
    }

    private var currentLanguage: String {
        return aiViewModel.selectedCodeCard?.language ?? "text"
    }

    // State to track view updates
    @State private var forceRefresh: UUID = UUID()

    var body: some View {
        ZStack {
            // Use the GlassBox component as the background
            GlassBox(title: "", height: 400)

            VStack(alignment: .leading, spacing: 12) {
                // Title area
                HStack {
                    Text(currentTitle)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    // Language badge
                    Text(currentLanguage)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(6)
                        .foregroundColor(.white)
                }

                Divider()
                    .background(Color.white.opacity(0.3))

                // Code content area - takes remaining space
                ZStack {
                    if !currentCode.isEmpty {
                        ScrollView(.vertical, showsIndicators: true) {
                            Text(currentCode)
                                .font(.system(size: 14, weight: .regular, design: .monospaced))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .textSelection(.enabled)
                        }
                    } else {
                        Text("No code available")
                            .foregroundColor(.white.opacity(0.6))
                            .italic()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.2))
                .cornerRadius(8)
            }
            .padding(20)
            .onReceive(aiViewModel.$selectedCodeCard) { newCard in
                if newCard != nil {
                    // Force a refresh by generating a new UUID
                    forceRefresh = UUID()
                }
            }
        }
    }
}

//struct OutputCodePreview: View {
//    var body: some View {
//        OutputCodeView()
//            .frame(width: 500, height: 400)
//            .background(Color.black)
//            .previewWithMockEnvironment()
//    }
//}

#Preview {
    OutputCodeView()
        .environmentObject(MinimizeViewModel())
        .environmentObject(VoiceBarViewModel())
        .environmentObject(AIViewModel())
}
