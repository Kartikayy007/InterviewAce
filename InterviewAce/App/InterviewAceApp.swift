import FirebaseCore
import FirebaseVertexAI

import SwiftUI
@main
struct InterviewAceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // This will only be needed if voiceViewModel is optional in AppDelegate
    private var safeVoiceViewModel: VoiceBarViewModel {
        // Only use the nil coalescing if voiceViewModel is optional
        return appDelegate.voiceViewModel
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate.minimizeViewModel)
                .environmentObject(safeVoiceViewModel)
                .environmentObject(appDelegate.aiViewModel)
        }
    }
}
