//
//  MarkdownUIView.swift
//  InterviewAce
//
//  Created by Kartikay on 01/05/25.
//

import SwiftUI
import MarkdownUI

/// A view that renders Markdown content using the MarkdownUI library
struct MarkdownUIView: View {
    let markdownContent: String
    var fontSize: CGFloat = 16
    var textColor: Color = .white

    var body: some View {
        // Parse the markdown content
        let content = MarkdownContent(markdownContent)

        Markdown(content)
            .markdownTheme(.custom)
            .textSelection(.enabled)
            // Add custom styling for code blocks
            .markdownBlockStyle(\.codeBlock) { configuration in
                VStack(alignment: .leading, spacing: 8) {
                    // Language badge and copy button
                    if let language = configuration.language {
                        HStack {
                            Text(language)
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.4))
                                .cornerRadius(4)
                                .foregroundColor(.white.opacity(0.95))

                            Spacer()

                            // Copy button
                            Button(action: {
                                // Extract the code text from the configuration
                                if let codeText = extractCodeText(from: configuration) {
                                    let pasteboard = NSPasteboard.general
                                    pasteboard.clearContents()
                                    pasteboard.setString(codeText, forType: .string)
                                }
                            }) {
                                Text("Copy")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .background(Color.blue.opacity(0.4))
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.blue.opacity(0.6), lineWidth: 1)
                            )
                        }
                    }

                    // Code content
                    configuration.label
                        .padding(12)
                        .markdownTextStyle {
                            FontFamilyVariant(.monospaced)
                            FontSize(.em(0.85))
                            ForegroundColor(.white.opacity(0.95))
                        }
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                .markdownMargin(top: 16, bottom: 16)
            }
            // Add custom styling for inline code
            .markdownTextStyle(\.code) {
                FontFamilyVariant(.monospaced)
                FontSize(.em(0.85))
                BackgroundColor(Color.black.opacity(0.3))
                ForegroundColor(.white.opacity(0.95))
            }
    }
}

// Custom MarkdownUI theme to match the app's design
extension Theme {
    static let custom = Theme()
        // Text styles
        .text {
            ForegroundColor(.white.opacity(0.9))
            FontSize(.em(1.0))
            FontWeight(.regular)
        }
        .strong {
            FontWeight(.bold)
            ForegroundColor(.white)
        }
        .emphasis {
            FontStyle(.italic)
        }
        .heading1 { configuration in
            configuration.label
                .markdownMargin(top: 24, bottom: 16)
                .markdownTextStyle {
                    FontWeight(.bold)
                    FontSize(.em(1.8))
                    ForegroundColor(.white)
                }
        }
        .heading2 { configuration in
            configuration.label
                .markdownMargin(top: 20, bottom: 12)
                .markdownTextStyle {
                    FontWeight(.bold)
                    FontSize(.em(1.5))
                    ForegroundColor(.white)
                }
        }
        .heading3 { configuration in
            configuration.label
                .markdownMargin(top: 16, bottom: 8)
                .markdownTextStyle {
                    FontWeight(.bold)
                    FontSize(.em(1.3))
                    ForegroundColor(.white)
                }
        }
        .heading4 { configuration in
            configuration.label
                .markdownMargin(top: 12, bottom: 4)
                .markdownTextStyle {
                    FontWeight(.bold)
                    FontSize(.em(1.1))
                    ForegroundColor(.white)
                }
        }
        .paragraph { configuration in
            configuration.label
                .markdownMargin(top: 0, bottom: 16)
                .lineSpacing(4)
        }
        .link {
            ForegroundColor(.blue)
        }
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(.em(0.85))
            BackgroundColor(Color.black.opacity(0.3))
            ForegroundColor(.white.opacity(0.95))
        }
        // Block styles
        .codeBlock { configuration in
            configuration.label
                .padding(12)
                .markdownTextStyle {
                    FontFamilyVariant(.monospaced)
                    FontSize(.em(0.85))
                    ForegroundColor(.white.opacity(0.95))
                }
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .markdownMargin(top: 16, bottom: 16)
        }
        .blockquote { configuration in
            configuration.label
                .padding()
                .markdownTextStyle {
                    FontStyle(.italic)
                    ForegroundColor(.white.opacity(0.8))
                }
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Color.blue.opacity(0.6))
                        .frame(width: 4)
                }
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
                .markdownMargin(top: 16, bottom: 16)
        }
        .listItem { configuration in
            configuration.label
                .markdownMargin(top: .em(0.25))
        }
}

// Helper function to extract code text from a code block configuration
private func extractCodeText(from configuration: CodeBlockConfiguration) -> String? {
    // In MarkdownUI, we can access the code content directly from the configuration
    return configuration.content
}

#Preview {
    ScrollView {
        MarkdownUIView(markdownContent: """
        # Heading 1
        ## Heading 2
        ### Heading 3

        This is a paragraph with **bold** and *italic* text.

        - List item 1
        - List item 2
          - Nested item

        > This is a blockquote with some text.

        ```swift
        func example() -> String {
            return "Hello, World!"
        }
        ```

        [Link to example](https://example.com)
        """)
        .padding()
    }
    .frame(width: 500, height: 500)
    .background(Color.black)
}
