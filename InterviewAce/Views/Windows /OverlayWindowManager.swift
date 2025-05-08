//
//  OverlayWindowManager.swift
//  InterviewAce
//
//  Created by kartikay on 01/05/25.
//

import Cocoa

class OverlayWindowManager {
    private var window: NSWindow
    private let animationDuration: TimeInterval = 0.2
    
    // Movement increment (pixels)
    let moveStep: CGFloat = 20
    let fastMoveStep: CGFloat = 100
    
    // Window's vertical position (fixed at top)
    private var topOffset: CGFloat = 0
    
    init(window: NSWindow) {
        self.window = window
        
        // Set the window to the top of the screen initially
        anchorToTop()
    }
    
    func anchorToTop() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        
        // Calculate top position with a small margin from the top
        topOffset = screenFrame.maxY - window.frame.height - 10
        
        // Set initial position - only change y coordinate
        var frame = window.frame
        frame.origin.y = topOffset
        
        // Use setFrameOrigin to only change y position without affecting x
        window.setFrameOrigin(NSPoint(x: frame.origin.x, y: topOffset))
    }
    
    func moveWindow(xDelta: CGFloat, yDelta: CGFloat) {
        // Only consider horizontal movement
        var frame = window.frame
        let newX = frame.origin.x + xDelta
        
        // No bounds checking - allow window to move outside screen
        frame.origin.x = newX
        
        // Keep the y position fixed at the top
        frame.origin.y = topOffset
        
        // Animate the movement
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = animationDuration
            window.animator().setFrame(frame, display: true)
        }, completionHandler: nil)
    }
    
    func centerWindow() {
        guard let screen = NSScreen.main else { return }
        
        // Get the full screen frame (not just visible area)
        let screenFrame = screen.frame
        let windowFrame = window.frame
        
        let newOrigin = NSPoint(
            x: screenFrame.midX - windowFrame.width / 2,
            y: topOffset // Keep vertical position fixed at top
        )
        
        // Animate the movement
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = animationDuration
            window.animator().setFrameOrigin(newOrigin)
        }, completionHandler: nil)
    }
    
    func moveWindowToCorner(corner: ScreenCorner) {
        guard let screen = NSScreen.main else { return }
        
        // Get the full screen frame (not just visible area)
        let screenFrame = screen.frame
        let windowFrame = window.frame
        var newOrigin = NSPoint()
        
        switch corner {
        case .topLeft:
            newOrigin = NSPoint(x: screenFrame.minX, y: topOffset)
        case .topRight:
            newOrigin = NSPoint(x: screenFrame.maxX - windowFrame.width, y: topOffset)
        case .bottomLeft:
            // For consistency, we're keeping the window at the top even with "bottom" corners
            newOrigin = NSPoint(x: screenFrame.minX, y: topOffset)
        case .bottomRight:
            newOrigin = NSPoint(x: screenFrame.maxX - windowFrame.width, y: topOffset)
        }
        
        // Animate the movement
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = animationDuration
            window.animator().setFrameOrigin(newOrigin)
        }, completionHandler: nil)
    }
    
    enum ScreenCorner {
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    func toggleVisibility() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.unhide(nil)
        
        if window.isVisible {
            window.orderOut(nil)
        } else {
            // When showing the window, make sure it's at the top position
            anchorToTop()
            
            // Don't reposition horizontally when showing - maintain last position
            // This preserves the window's horizontal position between hide/show
            
            window.orderFrontRegardless()
            window.makeKeyAndOrderFront(nil)
            NSApp.arrangeInFront(nil)
        }
    }
}
