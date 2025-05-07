import SwiftUI

/// A container view that applies animations to its content
struct AnimatedContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: true)
    }
}

#Preview {
    AnimatedContainer {
        Text("Animated Content")
            .padding()
            .background(Color.blue)
            .cornerRadius(8)
    }
}
