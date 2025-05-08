//
//  SecondaryBox.swift
//  InterviewAce
//
//  Created by kartikay on 01/05/25.
//


import SwiftUI

struct OutputCodeView: View {
    // Sample code for display
    private let sampleCode = """
    func exampleCode() {
        print("This is a sample code")

        // This view is no longer used in the app
        // It has been replaced by inline code in AIOutputView
        let message = "Hello, world!"
        print(message)
    }
    """

    private let title = "Sample Code"
    private let language = "swift"

    var body: some View {
        ZStack {
            // Use the GlassBox component as the background
            GlassBox(title: "", height: 500)

            VStack(alignment: .leading, spacing: 12) {
                // Title area
                HStack {
                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    // Language badge
                    Text(language)
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
                    ScrollView(.vertical, showsIndicators: true) {
                        Text(sampleCode)
                            .font(.system(size: 14, weight: .regular, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .textSelection(.enabled)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.2))
                .cornerRadius(8)
            }
            .padding(20)
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
        .background(Color.black.opacity(0.5))
}
