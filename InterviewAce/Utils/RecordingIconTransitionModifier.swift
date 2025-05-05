import SwiftUI

struct RecordingIconTransitionModifier: ViewModifier {
    let isIdentity: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isIdentity ? 1 : 0.5)
            .opacity(isIdentity ? 1 : 0)
            .blur(radius: isIdentity ? 0 : 10)
    }
}