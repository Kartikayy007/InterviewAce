import Cocoa
import HotKey

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowManager: WindowManager?
    var mainWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let window = NSApp.windows.first else { return }
        mainWindow = window

        // Configure the window
        configureWindow(window)
        
        // Initialize the WindowManager with this window
        windowManager = WindowManager(window: window)
    }
    
    private func configureWindow(_ window: NSWindow) {
        window.sharingType = .none
        
        // Window Configuration (Transparent, No Title Bar)
        window.isOpaque = false
        window.backgroundColor = NSColor.black.withAlphaComponent(0.05)
        window.titleVisibility = .hidden
        window.styleMask = [.borderless]
        // Simplified style mask for a borderless window
    }
}
