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
        case "swift":
            highlightSwiftCode(attributedString, string: string)
        case "python":
            highlightPythonCode(attributedString, string: string)
        case "javascript", "typescript":
            highlightJavaScriptCode(attributedString, string: string)
        case "java":
            highlightJavaCode(attributedString, string: string)
        case "c", "cpp", "csharp":
            highlightCStyleCode(attributedString, string: string)
        case "go", "rust":
            highlightCode(attributedString, string: string)
        default:
            // For unknown languages, just use basic highlighting
            highlightCode(attributedString, string: string)
        }

        // Apply the attributed string to the text view
        textView.textStorage?.setAttributedString(attributedString)
    }

    /// Apply Python-specific syntax highlighting
    static private func highlightPythonCode(_ attributedString: NSMutableAttributedString, string: String) {
        // Python keywords
        let keywords = ["def", "class", "if", "elif", "else", "for", "while", "return", "import", "from",
                        "as", "try", "except", "finally", "with", "in", "is", "not", "and", "or",
                        "True", "False", "None", "lambda", "global", "nonlocal", "pass", "break",
                        "continue", "yield", "assert", "del", "raise", "async", "await"]

        // Python built-in functions
        let builtins = ["print", "len", "range", "enumerate", "dict", "list", "tuple", "set", "int",
                        "str", "float", "bool", "map", "filter", "zip", "sum", "min", "max", "sorted",
                        "reversed", "any", "all", "abs", "round", "open", "type"]

        // Comments
        let commentPattern = "#.*$"

        // Strings
        let stringPattern = "\"\"\"[\\s\\S]*?\"\"\"|'''[\\s\\S]*?'''|\"[^\"\\\\]*(\\\\.[^\"\\\\]*)*\"|'[^'\\\\]*(\\\\.[^'\\\\]*)*'"

        // Numbers
        let numberPattern = "\\b\\d+(\\.\\d+)?\\b"

        // Decorators
        let decoratorPattern = "@\\w+(\\.\\w+)*"

        // Highlight keywords
        for keyword in keywords {
            let pattern = "\\b\(keyword)\\b"
            highlightPattern(pattern, in: attributedString, string: string, color: NSColor.systemPink)
        }

        // Highlight built-ins
        for builtin in builtins {
            let pattern = "\\b\(builtin)\\b"
            highlightPattern(pattern, in: attributedString, string: string, color: NSColor.systemBlue)
        }

        // Highlight comments
        highlightPattern(commentPattern, in: attributedString, string: string, color: NSColor.systemGreen)

        // Highlight strings
        highlightPattern(stringPattern, in: attributedString, string: string, color: NSColor.systemRed)

        // Highlight numbers
        highlightPattern(numberPattern, in: attributedString, string: string, color: NSColor.systemOrange)

        // Highlight decorators
        highlightPattern(decoratorPattern, in: attributedString, string: string, color: NSColor.systemPurple)
    }

    /// Apply Swift-specific syntax highlighting
    static private func highlightSwiftCode(_ attributedString: NSMutableAttributedString, string: String) {
        // Swift keywords
        let keywords = ["func", "let", "var", "if", "else", "for", "while", "return", "class", "struct",
                        "enum", "switch", "case", "break", "continue", "import", "public", "private",
                        "internal", "fileprivate", "static", "final", "void", "Int", "String", "Bool",
                        "true", "false", "nil", "self", "super", "init", "deinit", "get", "set", "weak",
                        "unowned", "guard", "defer", "throw", "throws", "rethrows", "try", "catch",
                        "protocol", "extension", "where", "associatedtype", "typealias", "as", "is",
                        "in", "mutating", "nonmutating", "convenience", "required", "override", "final"]

        // Comments
        let singleLineCommentPattern = "//.*$"
        let multiLineCommentPattern = "/\\*[\\s\\S]*?\\*/"

        // Strings
        let stringPattern = "\"\"\"[\\s\\S]*?\"\"\"|\"[^\"\\\\]*(\\\\.[^\"\\\\]*)*\""

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

    /// Apply JavaScript-specific syntax highlighting
    static private func highlightJavaScriptCode(_ attributedString: NSMutableAttributedString, string: String) {
        // JavaScript keywords
        let keywords = ["function", "let", "var", "const", "if", "else", "for", "while", "return", "class",
                        "switch", "case", "break", "continue", "import", "export", "default", "from",
                        "true", "false", "null", "undefined", "this", "super", "async", "await", "try",
                        "catch", "finally", "throw", "new", "delete", "typeof", "instanceof", "in", "of",
                        "yield", "static", "get", "set", "extends", "implements", "interface", "package",
                        "private", "protected", "public", "with", "as", "debugger"]

        // Built-in objects and functions
        let builtins = ["console", "document", "window", "Array", "Object", "String", "Number", "Boolean",
                        "Function", "Promise", "Map", "Set", "Date", "Math", "JSON", "Error", "RegExp"]

        // Comments
        let singleLineCommentPattern = "//.*$"
        let multiLineCommentPattern = "/\\*[\\s\\S]*?\\*/"

        // Strings
        let stringPattern = "`[^`\\\\]*(\\\\.[^`\\\\]*)*`|\"[^\"\\\\]*(\\\\.[^\"\\\\]*)*\"|'[^'\\\\]*(\\\\.[^'\\\\]*)*'"

        // Numbers
        let numberPattern = "\\b\\d+(\\.\\d+)?\\b"

        // Highlight keywords
        for keyword in keywords {
            let pattern = "\\b\(keyword)\\b"
            highlightPattern(pattern, in: attributedString, string: string, color: NSColor.systemPink)
        }

        // Highlight built-ins
        for builtin in builtins {
            let pattern = "\\b\(builtin)\\b"
            highlightPattern(pattern, in: attributedString, string: string, color: NSColor.systemBlue)
        }

        // Highlight comments
        highlightPattern(singleLineCommentPattern, in: attributedString, string: string, color: NSColor.systemGreen)
        highlightPattern(multiLineCommentPattern, in: attributedString, string: string, color: NSColor.systemGreen)

        // Highlight strings
        highlightPattern(stringPattern, in: attributedString, string: string, color: NSColor.systemRed)

        // Highlight numbers
        highlightPattern(numberPattern, in: attributedString, string: string, color: NSColor.systemOrange)
    }

    /// Apply Java-specific syntax highlighting
    static private func highlightJavaCode(_ attributedString: NSMutableAttributedString, string: String) {
        // Java keywords
        let keywords = ["abstract", "assert", "boolean", "break", "byte", "case", "catch", "char", "class",
                        "const", "con   tinue", "default", "do", "double", "else", "enum", "extends", "final",
                        "finally", "float", "for", "if", "implements", "import", "instanceof", "int",
                        "interface", "long", "native", "new", "package", "private", "protected", "public",
                        "return", "short", "static", "strictfp", "super", "switch", "synchronized", "this",
                        "throw", "throws", "transient", "try", "void", "volatile", "while", "true", "false",
                        "null"]

        // Comments
        let singleLineCommentPattern = "//.*$"
        let multiLineCommentPattern = "/\\*[\\s\\S]*?\\*/"

        // Strings
        let stringPattern = "\"[^\"\\\\]*(\\\\.[^\"\\\\]*)*\"|'[^'\\\\]*(\\\\.[^'\\\\]*)*'"

        // Numbers
        let numberPattern = "\\b\\d+(\\.\\d+)?[fFdDlL]?\\b"

        // Annotations
        let annotationPattern = "@\\w+"

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

        // Highlight annotations
        highlightPattern(annotationPattern, in: attributedString, string: string, color: NSColor.systemPurple)
    }

    /// Apply C-style syntax highlighting (C, C++, C#)
    static private func highlightCStyleCode(_ attributedString: NSMutableAttributedString, string: String) {
        // C-style keywords
        let keywords = ["auto", "break", "case", "char", "const", "continue", "default", "do", "double",
                        "else", "enum", "extern", "float", "for", "goto", "if", "int", "long", "register",
                        "return", "short", "signed", "sizeof", "static", "struct", "switch", "typedef",
                        "union", "unsigned", "void", "volatile", "while", "class", "namespace", "template",
                        "new", "delete", "this", "friend", "using", "public", "private", "protected",
                        "virtual", "inline", "operator", "overload", "true", "false", "null", "nullptr"]

        // Comments
        let singleLineCommentPattern = "//.*$"
        let multiLineCommentPattern = "/\\*[\\s\\S]*?\\*/"

        // Strings
        let stringPattern = "\"[^\"\\\\]*(\\\\.[^\"\\\\]*)*\"|'[^'\\\\]*(\\\\.[^'\\\\]*)*'"

        // Numbers
        let numberPattern = "\\b\\d+(\\.\\d+)?[fFlLuU]*\\b"

        // Preprocessor directives
        let preprocessorPattern = "#\\w+"

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

        // Highlight preprocessor directives
        highlightPattern(preprocessorPattern, in: attributedString, string: string, color: NSColor.systemPurple)
    }

    /// Apply basic syntax highlighting to code (fallback for other languages)
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
