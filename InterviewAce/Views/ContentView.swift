import SwiftUI

struct ContentView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @EnvironmentObject var minimizeVM: MinimizeViewModel
    @EnvironmentObject var voiceViewModel: VoiceBarViewModel
    @EnvironmentObject var aiViewModel: AIViewModel

    // Computed property to determine if we should show the AI output
    private var shouldShowAIOutput: Bool {
        if case .idle = aiViewModel.state {
            return false
        }
        return true
    }

    // Computed property to determine if we should show the code output
    private var shouldShowCodeOutput: Bool {
        return aiViewModel.selectedCodeCard != nil
    }

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                // TopBar is always visible
                TopBar()
                    .environmentObject(minimizeVM)
                    .opacity(1)
                    .background(minimizeVM.isMinimized ? Color.black.opacity(0.3) : Color.clear)
                    .cornerRadius(minimizeVM.isMinimized ? 16 : 0)
                    .padding(.horizontal, 0)

                if !minimizeVM.isMinimized {
                    // Main content area
                    HStack(spacing: 16) {
                        // Left column - Voice bar and AI output
                        VStack(spacing: 16) {
                            // Voice bar is always visible when not minimized
                            VoiceBar(viewModel: voiceViewModel)

                            // AI Output appears only when there's a response
                            AnimatedContainer {
                                if shouldShowAIOutput {
                                    AIOutputView()
                                        .environmentObject(aiViewModel)
                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                }
                            }
                        }

                        // Right column - Code output and tertiary box
                        AnimatedContainer {
                            if shouldShowCodeOutput {
                                VStack(spacing: 16) {
                                    // Ensure the same instance of AIViewModel is passed to both views
                                    let sharedViewModel = aiViewModel

                                    // Create a unique ID based on the selected card to force view recreation
                                    let selectedCard = sharedViewModel.selectedCodeCard
                                    let codeCardId = selectedCard?.id ?? "none"
                                    let codeLength = selectedCard?.code.count ?? 0

                                    // Force view recreation when selected card changes
                                    let viewId = "output-code-view-\(codeCardId)-\(codeLength)"

                                    OutputCodeView()
                                        .environmentObject(sharedViewModel)
                                        .id(viewId)

                                    TertiaryBox()
                                }
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                    }
                }
            }
            .padding(minimizeVM.isMinimized ? 0 : 20)
        }
        .frame(
            minWidth: minimizeVM.isMinimized ? 600 : 1000,
            maxWidth: minimizeVM.isMinimized ? 600 : 1000,
            minHeight: minimizeVM.isMinimized ? 80 : 700,
            maxHeight: minimizeVM.isMinimized ? 80 : 700
        )
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial.opacity(minimizeVM.isMinimized ? 0.0 : 0.1))
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.white.opacity(minimizeVM.isMinimized ? 0.0 : 0.1), radius: minimizeVM.isMinimized ? 0 : 10, x: 0, y: 5)
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

#Preview {
    AnimatedContainer {
        ContentView()
            .environmentObject(MinimizeViewModel())
            .environmentObject(VoiceBarViewModel())
            .environmentObject(AIViewModel())
    }
}
