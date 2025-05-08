import SwiftUI
//import SwiftUI.Observation

struct ContentView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @EnvironmentObject var minimizeVM: MinimizeViewModel
    @EnvironmentObject var voiceViewModel: VoiceBarViewModel
    @EnvironmentObject var aiViewModel: AIViewModel

    // State to track animation
    @State private var showAIOutput: Bool = false

    // Computed property to determine if we should show the AI output
    private var shouldShowAIOutput: Bool {
        // Show if we have a success response or if we're processing but had a previous response
        if case .success = aiViewModel.state {
            return true
        }
        if aiViewModel.isProcessing && !aiViewModel.response.isEmpty {
            return true
        }
        return false
    }

    // Update the showAIOutput state when the shouldShowAIOutput changes
    private func updateShowAIOutput() {
        if shouldShowAIOutput && !showAIOutput {
            // Use a slight delay to ensure the animation is visible
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showAIOutput = true
            }
        } else if !shouldShowAIOutput && showAIOutput {
            showAIOutput = false
        }
    }

    var body: some View {
        // Update the animation state when the view appears or when AI state changes
        ZStack {
            // Use a VStack with zero spacing to position elements
            VStack(spacing: 0) {
                // TopBar is always visible at the very top
                TopBar()
                    .environmentObject(minimizeVM)
                    .opacity(1)
                    .background(minimizeVM.isMinimized ? Color.black.opacity(0.3) : Color.clear)
                    .cornerRadius(minimizeVM.isMinimized ? 16 : 0)
                    .padding(.horizontal, 0)
                    .padding(.bottom, 10) // Add some space below the TopBar

                if !minimizeVM.isMinimized {
                    // Voice bar is always visible when not minimized and positioned right below TopBar
                    HStack {
                        Spacer()
                        VoiceBar(viewModel: voiceViewModel)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 5) // Add a small top padding

                    // AI Output appears only when there's a response
                    if shouldShowAIOutput {
                        HStack {
                            Spacer()
                            // Use the custom animation that grows from top to bottom
                            AIOutputView()
                                .environmentObject(aiViewModel)
                                .transition(.opacity)
                                .opacity(showAIOutput ? 1 : 0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showAIOutput)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10) // Add spacing between VoiceBar and AIOutputView
                    }

                    // Add a spacer to push everything to the top
                    Spacer()
                }
            }
            .padding(.top, minimizeVM.isMinimized ? 0 : 20)
        }
        .frame(
            minWidth: minimizeVM.isMinimized ? 600 : 1000,
            maxWidth: minimizeVM.isMinimized ? 600 : 1000,
            minHeight: minimizeVM.isMinimized ? 80 : 700,
            maxHeight: minimizeVM.isMinimized ? 80 : 700
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.white.opacity(minimizeVM.isMinimized ? 0.0 : 0.1), radius: minimizeVM.isMinimized ? 0 : 10, x: 0, y: 5)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onChange(of: shouldShowAIOutput) { _, newValue in
            updateShowAIOutput()
        }
        .onAppear {
            // Initialize the animation state when the view appears
            updateShowAIOutput()
        }
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
