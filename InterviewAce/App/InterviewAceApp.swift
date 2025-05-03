import SwiftUI

@main
struct InterviewAceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Create a safe voice view model that handles the nil case
    private var safeVoiceViewModel: VoiceBarViewModel {
        return appDelegate.voiceViewModel ?? VoiceBarViewModel()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate.minimizeViewModel)
                .environmentObject(safeVoiceViewModel)
        }
    }
}
