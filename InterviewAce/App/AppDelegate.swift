import Cocoa
import HotKey
import FirebaseCore


@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    // Add a static shared property
    static var shared: AppDelegate!
    
    // Use strong references to ensure services aren't deallocated
    var windowManager: OverlayWindowManager?
    
    var voiceViewModel = VoiceBarViewModel()
    var minimizeViewModel = MinimizeViewModel()
    var aiViewModel = AIViewModel()
    
    var screenshotService: ScreenshotService?
    var hotkeyService: HotkeyService?

    var mainWindow: NSWindow?

    // Alert controller for permission errors
    var permissionAlertController: NSAlert?

    // Property to store the original frame
    var savedWindowFrame: NSRect?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set the shared instance
        AppDelegate.shared = self
        
        // Initialize Firebase first
        FirebaseApp.configure()
        
        // Initialize services
        screenshotService = ScreenshotService()

        // The window might not be immediately available, so we add a slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setupInitialWindow()
        }

        // Register for notifications to handle window restore/reactivation
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(windowDidBecomeKey),
                                              name: NSWindow.didBecomeKeyNotification,
                                              object: nil)

        NotificationCenter.default.addObserver(self,
                                              selector: #selector(applicationDidBecomeActive),
                                              name: NSApplication.didBecomeActiveNotification,
                                              object: nil)

        // Also observe when new windows are added to the application
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(windowDidAppear),
                                              name: NSWindow.didUpdateNotification,
                                              object: nil)

        // Listen for screenshot notifications
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(screenshotTaken),
                                              name: .screenshotTaken,
                                              object: nil)

        // Listen for screenshot permission error notifications
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(handlePermissionError),
                                              name: .screenshotPermissionError,
                                              object: nil)

        // Listen for minimize toggle notifications
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(handleMinimizeToggle),
                                              name: .minimizeStateChanged,
                                              object: nil)

        // Setup voice transcript processing for AI
        setupVoiceTranscriptObserver()
        
        // Check screen recording permission proactively
        Task {
            await checkScreenRecordingPermission()
        }
    }
    
    private func setupVoiceTranscriptObserver() {
        // Use Combine to observe transcript changes from the VoiceViewModel
        voiceViewModel.objectWillChange
            .debounce(for: .seconds(2), scheduler: RunLoop.main) // Delay to accumulate speech
            .sink { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.aiViewModel.processTranscript(from: self.voiceViewModel)
                }
            }
            .store(in: &voiceViewModel.cancellables)
    }

    // Proactively check screen recording permission
    private func checkScreenRecordingPermission() async {
        // We'll let the ScreenshotService handle permission checking when needed
        print("ℹ️ Screen recording permission will be checked when taking a screenshot")
    }

    private func setupInitialWindow() {
        if let window = NSApp.windows.first {
            mainWindow = window

            // Configure the window
            configureWindow(window)

            // Initialize the WindowManager with this window
            if windowManager == nil {
                windowManager = OverlayWindowManager(window: window)
                hotkeyService = HotkeyService(
                    overlayManager: windowManager!,
                    voiceViewModel: voiceViewModel,
                    screenshotService: screenshotService,
                    minimizeViewModel: minimizeViewModel
                )
                print("OverlayWindowManager and HotkeyService initialized")
            }

            // Make sure window is visible and in front
            window.orderFrontRegardless()
            window.makeKeyAndOrderFront(nil)
        } else {
            // If window still not available, retry after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.setupInitialWindow()
            }
        }
    }

    @objc func applicationDidBecomeActive(_ notification: Notification) {
        // When the application becomes active, ensure windows are properly configured
        if let window = mainWindow {
            configureWindow(window)
        }

        // Reset the permission dialog flag in the screenshot service
        // This allows it to check permissions again if the user has granted them in System Settings
        if let screenshotService = screenshotService {
            screenshotService.resetPermissionDialogFlag()
        }
    }

    @objc func windowDidBecomeKey(_ notification: Notification) {
        // When a window becomes key (focused), ensure it's properly configured
        if let window = notification.object as? NSWindow {
            configureWindow(window)

            // Update main window reference if needed
            if mainWindow == nil {
                mainWindow = window

                if windowManager == nil {
                    windowManager = OverlayWindowManager(window: window)
                    hotkeyService = HotkeyService(
                        overlayManager: windowManager!,
                        voiceViewModel: voiceViewModel,
                        screenshotService: screenshotService,
                        minimizeViewModel: minimizeViewModel
                    )
                    print("OverlayWindowManager and HotkeyService initialized")
                }
            }
        }
    }

    @objc func windowDidAppear(_ notification: Notification) {
        // When a window updates (which includes appearing), ensure it's properly configured
        if let window = notification.object as? NSWindow {
            configureWindow(window)

            // Update main window reference if needed
            if mainWindow == nil {
                mainWindow = window

                if windowManager == nil {
                    windowManager = OverlayWindowManager(window: window)
                    hotkeyService = HotkeyService(
                        overlayManager: windowManager!,
                        voiceViewModel: voiceViewModel,
                        screenshotService: screenshotService,
                        minimizeViewModel: minimizeViewModel
                        
                    )
                    print("OverlayWindowManager and HotkeyService initialized")
                }
            }
        }
    }

    @objc func screenshotTaken(_ notification: Notification) {
        // Handle when a screenshot is taken
        if let fileURL = notification.userInfo?["fileURL"] as? URL {
            print("📣 Screenshot taken successfully - saved to: \(fileURL.path)")

            // You could add additional functionality here, such as:
            // - Show a notification to the user
            // - Play a sound
            // - Open the screenshot in Preview
            // - Copy the image to clipboard
        }
    }

    @objc func handlePermissionError(_ notification: Notification) {
        // Only show one alert at a time
        if permissionAlertController != nil {
            return
        }

        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Required"
        alert.informativeText = "InterviewAce needs screen recording permission to take screenshots. Please enable this in System Settings > Privacy & Security > Screen Recording."
        alert.alertStyle = .warning

        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")

        permissionAlertController = alert

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            // Open system preferences to screen recording permissions
            let prefUrl = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
            NSWorkspace.shared.open(prefUrl)
        }

        permissionAlertController = nil
    }

    @objc func handleMinimizeToggle(_ notification: Notification) {
        guard let isMinimized = notification.userInfo?["isMinimized"] as? Bool,
              let window = mainWindow else { return }
        
        // Get current frame
        var frame = window.frame
        
        if isMinimized {
            // Save current frame for restoration later
            AppDelegate.shared.savedWindowFrame = frame
            
            // Calculate new height - just enough for TopBar plus padding
            let minimizedHeight: CGFloat = 80
            
            // Keep the same width and x position, but adjust height and y position
            // Move window up to compensate for height reduction
            frame.origin.y = frame.origin.y + (frame.height - minimizedHeight)
            frame.size.height = minimizedHeight
            
            // Make window almost completely transparent when minimized
            window.alphaValue = 0.3
        } else {
            // Restore previous full size frame if we have one
            if let storedFrame = AppDelegate.shared.savedWindowFrame {
                frame = storedFrame
            }
            
            // Restore normal opacity
            window.alphaValue = 1.0
        }
        
        // Animate the frame change
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            window.animator().setFrame(frame, display: true)
        }
    }

    private func configureWindow(_ window: NSWindow) {
        window.sharingType = .none

        // Set background color with transparency
        window.backgroundColor = NSColor.clear
        window.titleVisibility = .hidden
        window.styleMask = [.borderless]

        window.level = .floating
        window.isReleasedWhenClosed = false

        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.isMovableByWindowBackground = false
        window.hidesOnDeactivate = false


        // Set window collection behavior
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle,
            NSWindow.CollectionBehavior(rawValue: 1 << 7)
        ]

        // If the window has a content view, set it up for click-through
        if let contentView = window.contentView {
            setupContentViewForClickThrough(contentView)
        }
    }

    private func setupContentViewForClickThrough(_ view: NSView) {
        // Make the content view itself ignore mouse events (click-through)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
    }
}
