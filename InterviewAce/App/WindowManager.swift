import Cocoa
import HotKey

class WindowManager {
    private weak var window: NSWindow?
    
    // Window toggle hotkey
    private var toggleHotKey: HotKey?
    
    // Window movement hotkeys
    private var moveLeftHotKey: HotKey?
    private var moveRightHotKey: HotKey?
    private var moveUpHotKey: HotKey?
    private var moveDownHotKey: HotKey?
    
    // Fast movement hotkeys
    private var fastMoveLeftHotKey: HotKey?
    private var fastMoveRightHotKey: HotKey?
    private var fastMoveUpHotKey: HotKey?
    private var fastMoveDownHotKey: HotKey?
    
    // Position hotkeys
    private var centerWindowHotKey: HotKey?
    private var topLeftCornerHotKey: HotKey?
    private var topRightCornerHotKey: HotKey?
    private var bottomLeftCornerHotKey: HotKey?
    private var bottomRightCornerHotKey: HotKey?
    
    // Movement increment (pixels)
    private let moveStep: CGFloat = 20
    private let fastMoveStep: CGFloat = 100
    
    init(window: NSWindow) {
        self.window = window
        
        // Setup all the keyboard shortcuts
        setupToggleShortcut()
        setupArrowKeyShortcuts()
        setupFastMovementShortcuts()
        setupCornerShortcuts()
        setupCenterShortcut()
    }
    
    private func setupToggleShortcut() {
        // Register Hotkey: Cmd + Shift + A to toggle window visibility
        toggleHotKey = HotKey(key: .a, modifiers: [.command, .shift])
        toggleHotKey?.keyDownHandler = { [weak self] in
            guard let self = self, let window = self.window else { return }
            
            if window.isVisible {
                window.orderOut(nil) // Hide the window
            } else {
                window.orderFrontRegardless() // Show the window (even if app is in background)
            }
        }
    }
    
    private func setupArrowKeyShortcuts() {
        // Move window left with Option + Left Arrow
        moveLeftHotKey = HotKey(key: .leftArrow, modifiers: [.option])
        moveLeftHotKey?.keyDownHandler = { [weak self] in
            self?.moveWindow(xDelta: -self!.moveStep, yDelta: 0)
        }
        
        // Move window right with Option + Right Arrow
        moveRightHotKey = HotKey(key: .rightArrow, modifiers: [.option])
        moveRightHotKey?.keyDownHandler = { [weak self] in
            self?.moveWindow(xDelta: self!.moveStep, yDelta: 0)
        }
        
        // Move window up with Option + Up Arrow
        moveUpHotKey = HotKey(key: .upArrow, modifiers: [.option])
        moveUpHotKey?.keyDownHandler = { [weak self] in
            self?.moveWindow(xDelta: 0, yDelta: self!.moveStep)
        }
        
        // Move window down with Option + Down Arrow
        moveDownHotKey = HotKey(key: .downArrow, modifiers: [.option])
        moveDownHotKey?.keyDownHandler = { [weak self] in
            self?.moveWindow(xDelta: 0, yDelta: -self!.moveStep)
        }
    }
    
    private func setupFastMovementShortcuts() {
        // Fast move window left with Shift + Option + Left Arrow
        fastMoveLeftHotKey = HotKey(key: .leftArrow, modifiers: [.option, .shift])
        fastMoveLeftHotKey?.keyDownHandler = { [weak self] in
            self?.moveWindow(xDelta: -self!.fastMoveStep, yDelta: 0)
        }
        
        // Fast move window right with Shift + Option + Right Arrow
        fastMoveRightHotKey = HotKey(key: .rightArrow, modifiers: [.option, .shift])
        fastMoveRightHotKey?.keyDownHandler = { [weak self] in
            self?.moveWindow(xDelta: self!.fastMoveStep, yDelta: 0)
        }
        
        // Fast move window up with Shift + Option + Up Arrow
        fastMoveUpHotKey = HotKey(key: .upArrow, modifiers: [.option, .shift])
        fastMoveUpHotKey?.keyDownHandler = { [weak self] in
            self?.moveWindow(xDelta: 0, yDelta: self!.fastMoveStep)
        }
        
        // Fast move window down with Shift + Option + Down Arrow
        fastMoveDownHotKey = HotKey(key: .downArrow, modifiers: [.option, .shift])
        fastMoveDownHotKey?.keyDownHandler = { [weak self] in
            self?.moveWindow(xDelta: 0, yDelta: -self!.fastMoveStep)
        }
    }
    
    private func setupCornerShortcuts() {
        // Top-left corner (Control + 1)
        topLeftCornerHotKey = HotKey(key: .one, modifiers: [.control])
        topLeftCornerHotKey?.keyDownHandler = { [weak self] in
            self?.moveWindowToCorner(corner: .topLeft)
        }
        
        // Top-right corner (Control + 2)
        topRightCornerHotKey = HotKey(key: .two, modifiers: [.control])
        topRightCornerHotKey?.keyDownHandler = { [weak self] in
            self?.moveWindowToCorner(corner: .topRight)
        }
        
        // Bottom-left corner (Control + 3)
        bottomLeftCornerHotKey = HotKey(key: .three, modifiers: [.control])
        bottomLeftCornerHotKey?.keyDownHandler = { [weak self] in
            self?.moveWindowToCorner(corner: .bottomLeft)
        }
        
        // Bottom-right corner (Control + 4)
        bottomRightCornerHotKey = HotKey(key: .four, modifiers: [.control])
        bottomRightCornerHotKey?.keyDownHandler = { [weak self] in
            self?.moveWindowToCorner(corner: .bottomRight)
        }
    }
    
    private func setupCenterShortcut() {
        // Center window on screen (Control + Space)
        centerWindowHotKey = HotKey(key: .space, modifiers: [.control])
        centerWindowHotKey?.keyDownHandler = { [weak self] in
            self?.centerWindow()
        }
    }
    
    // Helper function to move window by delta
    private func moveWindow(xDelta: CGFloat, yDelta: CGFloat) {
        guard let window = window else { return }
        
        var frame = window.frame
        frame.origin.x += xDelta
        frame.origin.y += yDelta
        window.setFrame(frame, display: true)
    }
    
    // Helper function to center window on screen
    private func centerWindow() {
        guard let window = window, let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame
        
        let newOrigin = NSPoint(
            x: screenFrame.midX - windowFrame.width / 2,
            y: screenFrame.midY - windowFrame.height / 2
        )
        
        window.setFrameOrigin(newOrigin)
    }
    
    // Helper enum for corner positioning
    private enum ScreenCorner {
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    // Helper function to move window to a screen corner
    private func moveWindowToCorner(corner: ScreenCorner) {
        guard let window = window, let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame
        var newOrigin = NSPoint()
        
        switch corner {
        case .topLeft:
            newOrigin = NSPoint(x: screenFrame.minX, y: screenFrame.maxY - windowFrame.height)
        case .topRight:
            newOrigin = NSPoint(x: screenFrame.maxX - windowFrame.width, y: screenFrame.maxY - windowFrame.height)
        case .bottomLeft:
            newOrigin = NSPoint(x: screenFrame.minX, y: screenFrame.minY)
        case .bottomRight:
            newOrigin = NSPoint(x: screenFrame.maxX - windowFrame.width, y: screenFrame.minY)
        }
        
        window.setFrameOrigin(newOrigin)
    }
}
