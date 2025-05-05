import SwiftUI

struct ContentView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @EnvironmentObject var minimizeVM: MinimizeViewModel
    @EnvironmentObject var voiceViewModel: VoiceBarViewModel
    @EnvironmentObject var aiViewModel: AIViewModel

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                TopBar()
                    .environmentObject(minimizeVM)
                    .opacity(1) // Always visible
                    .background(minimizeVM.isMinimized ? Color.black.opacity(0.3) : Color.clear) // Add background to TopBar when minimized
                    .cornerRadius(minimizeVM.isMinimized ? 16 : 0) // Make TopBar rounded when minimized
                    .padding(.horizontal, 0) // Consistent padding in both states
                
                if !minimizeVM.isMinimized {
                    HStack(spacing: 16) {
                        VStack(spacing: 16) {
                            VoiceBar(viewModel: voiceViewModel)
                            AIOutputView()
                                .environmentObject(aiViewModel)
                        }

                        VStack(spacing: 16) {
                            OutputCodeView()
                            TertiaryBox()
                        }
                    }
                    .opacity(minimizeVM.isMinimized ? 0 : 1) // Hide content but not TopBar when minimized
                }
            }
            .padding(minimizeVM.isMinimized ? 0 : 20) // Remove padding when minimized
        }
        .frame(
            minWidth: minimizeVM.isMinimized ? 600 : 1000,  // Increase minimized width to fit content
            maxWidth: minimizeVM.isMinimized ? 600 : 1000,  // Increase minimized width to fit content
            minHeight: minimizeVM.isMinimized ? 80 : 700,
            maxHeight: minimizeVM.isMinimized ? 80 : 700
        )
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial.opacity(minimizeVM.isMinimized ? 0.0 : 0.1)) // Completely transparent when minimized
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.white.opacity(minimizeVM.isMinimized ? 0.0 : 0.1), radius: minimizeVM.isMinimized ? 0 : 10, x: 0, y: 5)
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

#Preview {
    ContentView()
        .environmentObject(MinimizeViewModel())
        .environmentObject(VoiceBarViewModel())
        .environmentObject(AIViewModel())
}
