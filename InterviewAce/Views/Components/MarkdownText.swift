import SwiftUI
import AppKit

/// A view that renders Markdown text
struct MarkdownText: View {
    let text: String
    var fontSize: CGFloat = 16
    @AppStorage("isDarkMode") private var isDarkMode = true

    // Dynamic text color based on isDarkMode
    private var textColor: Color {
        isDarkMode ? .white : .black
    }

    // Return the original text without removing code blocks
    private var processedText: String {
        return text
    }

    var body: some View {
        if #available(macOS 12.0, *) {
            // Use the built-in Markdown support
            Text(attributedMarkdownText)
                .textSelection(.enabled)
                .lineSpacing(4)
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .id("markdowntext-\(isDarkMode)") // Force view refresh when theme changes
        } else {
            // Fallback for older versions
            Text(processedText)
                .textSelection(.enabled)
                .foregroundColor(textColor)
                .font(.system(size: fontSize))
                .lineSpacing(4)
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .id("markdowntext-\(isDarkMode)") // Force view refresh when theme changes
        }
    }

    // Create AttributedString from markdown
    @available(macOS 12.0, *)
    private var attributedMarkdownText: AttributedString {
        do {
            // First parse the markdown into an AttributedString
            var attributedString = try AttributedString(markdown: processedText, options: AttributedString.MarkdownParsingOptions(
                allowsExtendedAttributes: true,
                interpretedSyntax: .inlineOnlyPreservingWhitespace,
                failurePolicy: .returnPartiallyParsedIfPossible
            ))

            // Apply foreground color based on the theme
            attributedString.foregroundColor = textColor

            return attributedString
        } catch {
            print("Error parsing markdown: \(error)")
            // If parsing fails, return plain text
            var plainText = AttributedString(processedText)

            // Apply foreground color to plain text
            plainText.foregroundColor = textColor

            return plainText
        }
    }
}

// Extension to make NSColor from SwiftUI Color for macOS
extension NSColor {
    convenience init(_ color: Color) {
        let cgColor = color.cgColor ?? NSColor.white.cgColor
        self.init(cgColor: cgColor)!
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        MarkdownText(text: "# This is a heading\n\nThis is **bold** and *italic* text.\n\n- List item 1\n- List item 2\n\n```swift\nlet code = \"example\"\n```")
            .padding()
    }
    .frame(width: 400, height: 300)
    .background(Color.black)
}