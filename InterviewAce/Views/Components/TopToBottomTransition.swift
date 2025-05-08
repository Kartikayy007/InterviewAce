import SwiftUI

/// A custom transition that makes a view appear from the top and grow downward
struct TopToBottomTransition: ViewModifier {
    let isActive: Bool
    let animation: Animation

    func body(content: Content) -> some View {
        content
            .frame(height: isActive ? nil : 0, alignment: .top)
            .clipped()
            .animation(animation, value: isActive)
    }
}

extension AnyTransition {
    /// Creates a transition that makes the view appear from the top and grow downward
    static var topToBottom: AnyTransition {
        .modifier(
            active: TopToBottomTransition(isActive: false, animation: .spring(response: 0.5, dampingFraction: 0.8)),
            identity: TopToBottomTransition(isActive: true, animation: .spring(response: 0.5, dampingFraction: 0.8))
        )
    }
}

/// A custom transition that slides a view in from the top
struct SlideFromTopTransition: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isActive)
    }
}

extension View {
    /// Applies a slide-from-top transition to a view
    func slideFromTop(isActive: Bool) -> some View {
        modifier(SlideFromTopTransition(isActive: isActive))
    }
}
