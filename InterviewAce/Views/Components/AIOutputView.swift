import SwiftUI
import AppKit
import MarkdownUI

/// Main content box shown below the voice bar
struct AIOutputView: View {
    @EnvironmentObject var aiViewModel: AIViewModel

    // State to track content size
    @State private var contentHeight: CGFloat = 0

    // Minimum and maximum height for the AIOutputView
    private let minHeight: CGFloat = 100 // Minimum height for short responses
    private let maxHeight: CGFloat = 500 // Maximum height before scrolling

    var body: some View {
        // Use a ZStack to layer the content
        ZStack {
            // Use the GlassBox component as the background with dynamic height
            GlassBox(title: "", height: min(max(contentHeight + 40, minHeight), maxHeight))
                .contentShape(Rectangle()) // Ensure the entire area is tappable

            VStack(alignment: .leading, spacing: 12) {
                ScrollView {
                    responseContent
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: ContentHeightPreferenceKey.self,
                                    value: geo.size.height
                                )
                            }
                        )
                }
                .frame(height: min(contentHeight, maxHeight - 40))
            }
            .padding(20)
            .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
                self.contentHeight = height
            }
        }
        .frame(width: 700)
        .animation(.easeInOut(duration: 0.2), value: contentHeight)
    }

    // Preference key to track content height
    struct ContentHeightPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
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
            // If we have a previous response, show it while processing
            if !aiViewModel.response.isEmpty {
                displayResponseContent(aiViewModel.response)
                    .opacity(0.7) // Dim the previous response to indicate it's being updated
            } else {
                // Otherwise show the thinking message
                VStack(alignment: .leading, spacing: 16) {
                    Text("Thinking...")
                        .foregroundColor(.white.opacity(0.7))
                        .italic()
                        .font(.system(size: 16))
                }
            }

        case .success(let responseText):
            displayResponseContent(responseText)

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

    @ViewBuilder
    private func displayResponseContent(_ responseText: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Debug log
            let _ = print("AIOutputView: Displaying response of length \(responseText.count)")

            if let markdownContent = aiViewModel.markdownContent {
                // Use MarkdownUI's Markdown view directly if we have parsed content
                Markdown(markdownContent)
                    .markdownTheme(.custom)
                    .textSelection(.enabled)
            } else {
                // Fallback to our custom view if parsing failed
                MarkdownUIView(markdownContent: responseText)
            }
        }
    }
}

//#Preview {
//    AIOutputView()
//        .environmentObject(AIViewModel())
//        .frame(width: 500, height: 500)
//        .background(Color.black)
//}
