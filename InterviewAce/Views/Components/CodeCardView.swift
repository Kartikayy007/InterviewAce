import SwiftUI

/// A view that displays a code card with a title and code snippet
struct CodeCardView: View {
    let codeCard: AIResponseModel.CodeCard
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title bar
            HStack {
                Text(codeCard.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Language badge
                Text(codeCard.language)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.3))
                    .cornerRadius(4)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            // Code preview (truncated)
            Text(codePreview)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
        .onTapGesture {
            onSelect()
        }
    }
    
    // Computed property to get a preview of the code (first few lines)
    private var codePreview: String {
        let lines = codeCard.code.split(separator: "\n")
        if lines.count <= 3 {
            return codeCard.code
        } else {
            return lines.prefix(3).joined(separator: "\n") + "\n..."
        }
    }
}

#Preview {
    VStack {
        CodeCardView(
            codeCard: AIResponseModel.CodeCard(
                title: "Example Code",
                language: "swift",
                code: "func example() {\n    print(\"Hello, world!\")\n}"
            ),
            isSelected: false,
            onSelect: {}
        )
        
        CodeCardView(
            codeCard: AIResponseModel.CodeCard(
                title: "Selected Example",
                language: "javascript",
                code: "function example() {\n    console.log(\"Hello, world!\");\n}"
            ),
            isSelected: true,
            onSelect: {}
        )
    }
    .padding()
    .background(Color.black)
}
