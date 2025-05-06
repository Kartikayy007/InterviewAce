import SwiftUI
import AppKit

/// A view that displays code with syntax highlighting and editing capabilities
struct CodeEditorView: View {
    @Binding var code: String
    let language: String
    let isEditable: Bool

    // Add an ID to force refresh when code changes
    private var codeId: String {
        return "\(code.hashValue)-\(language)"
    }

    var body: some View {
        VStack {
            // Add a debug label to show code length
            Text("Editor code length: \(code.count) chars")
                .font(.system(size: 10))
                .foregroundColor(.gray.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.bottom, 2)

            GeometryReader { geometry in
                CodeTextView(
                    code: $code,
                    language: language,
                    isEditable: isEditable,
                    size: geometry.size
                )
            }
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
        }
        .id(codeId) // Force refresh when code changes
    }
}

/// NSViewRepresentable wrapper for NSTextView with syntax highlighting
struct CodeTextView: NSViewRepresentable {
    @Binding var code: String
    let language: String
    let isEditable: Bool
    let size: CGSize

    func makeNSView(context: Context) -> NSScrollView {
        // Create text components
        let storage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        storage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(size: size)
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)

        // Create text view
        let textView = NSTextView(frame: .zero, textContainer: textContainer)
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textColor = NSColor.white
        textView.backgroundColor = NSColor.clear

        // Set up auto-indent
        textView.enabledTextCheckingTypes = 0
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false

        // Set up line numbers and syntax highlighting
        textView.string = code
        CodeTextView.applySyntaxHighlighting(to: textView, language: language)

        // Set the delegate to handle text changes
        textView.delegate = context.coordinator

        // Create a scroll view to contain the text view
        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.drawsBackground = false

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else {
            print("CodeTextView: Failed to get textView from scrollView")
            return
        }

        // Always update the text to ensure it's current
        print("CodeTextView: Updating text view with \(code.count) chars")
        textView.string = code
        CodeTextView.applySyntaxHighlighting(to: textView, language: language)

        // Scroll to the top
        textView.scrollToBeginningOfDocument(nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CodeTextView

        init(_ parent: CodeTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.code = textView.string
            CodeTextView.applySyntaxHighlighting(to: textView, language: parent.language)
        }
    }

    /// Apply basic syntax highlighting based on language
    static func applySyntaxHighlighting(to textView: NSTextView, language: String) {
        let string = textView.string
        let attributedString = NSMutableAttributedString(string: string)

        // Default text color
        attributedString.addAttribute(.foregroundColor, value: NSColor.white, range: NSRange(location: 0, length: string.count))

        // Apply language-specific highlighting
        switch language.lowercased() {
        case "swift", "javascript", "python", "java", "c", "cpp", "csharp", "go", "rust", "typescript":
            highlightCode(attributedString, string: string)
        default:
            // For unknown languages, just use basic highlighting
            highlightCode(attributedString, string: string)
        }

        // Apply the attributed string to the text view
        textView.textStorage?.setAttributedString(attributedString)
    }

    /// Apply basic syntax highlighting to code
    static private func highlightCode(_ attributedString: NSMutableAttributedString, string: String) {
        // Keywords (common across many languages)
        let keywords = ["func", "let", "var", "if", "else", "for", "while", "return", "class", "struct",
                        "enum", "switch", "case", "break", "continue", "import", "public", "private",
                        "protected", "static", "final", "void", "int", "string", "bool", "true", "false",
                        "null", "nil", "self", "this", "super", "function", "const", "async", "await"]

        // Comments
        let singleLineCommentPattern = "//.*$"
        let multiLineCommentPattern = "/\\*[\\s\\S]*?\\*/"

        // Strings
        let stringPattern = "\"[^\"\\\\]*(\\\\.[^\"\\\\]*)*\"|'[^'\\\\]*(\\\\.[^'\\\\]*)*'"

        // Numbers
        let numberPattern = "\\b\\d+(\\.\\d+)?\\b"

        // Highlight keywords
        for keyword in keywords {
            let pattern = "\\b\(keyword)\\b"
            highlightPattern(pattern, in: attributedString, string: string, color: NSColor.systemPink)
        }

        // Highlight comments
        highlightPattern(singleLineCommentPattern, in: attributedString, string: string, color: NSColor.systemGreen)
        highlightPattern(multiLineCommentPattern, in: attributedString, string: string, color: NSColor.systemGreen)

        // Highlight strings
        highlightPattern(stringPattern, in: attributedString, string: string, color: NSColor.systemRed)

        // Highlight numbers
        highlightPattern(numberPattern, in: attributedString, string: string, color: NSColor.systemOrange)
    }

    /// Highlight a specific pattern in the attributed string
    static private func highlightPattern(_ pattern: String, in attributedString: NSMutableAttributedString, string: String, color: NSColor) {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: string, options: [], range: NSRange(location: 0, length: string.count))

            for match in matches {
                attributedString.addAttribute(.foregroundColor, value: color, range: match.range)
            }
        } catch {
            print("Error creating regex: \(error)")
        }
    }
}

#Preview {
    CodeEditorView(
        code: .constant("func example() {\n    print(\"Hello, world!\")\n}"),
        language: "swift",
        isEditable: true
    )
    .frame(height: 200)
    .padding()
    .background(Color.black)
}
