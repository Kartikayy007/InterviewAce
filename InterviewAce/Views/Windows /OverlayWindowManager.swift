//
//  OverlayWindowManager.swift
//  InterviewAce
//
//  Created by kartikay on 01/05/25.
//

import Cocoa

class OverlayWindowManager {
    private var window: NSWindow

    // Movement increment (pixels)
    let moveStep: CGFloat = 20
    let fastMoveStep: CGFloat = 100

    init(window: NSWindow) {
        self.window = window
    }

    func moveWindow(xDelta: CGFloat, yDelta: CGFloat) {
        var frame = window.frame
        frame.origin.x += xDelta
        frame.origin.y += yDelta
        window.setFrame(frame, display: true)
    }

    func centerWindow() {
        guard let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame

        let newOrigin = NSPoint(
            x: screenFrame.midX - windowFrame.width / 2,
            y: screenFrame.midY - windowFrame.height / 2
        )

        window.setFrameOrigin(newOrigin)
    }

    func moveWindowToCorner(corner: ScreenCorner) {
        guard let screen = NSScreen.main else { return }

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

    enum ScreenCorner {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    func toggleVisibility() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.unhide(nil)

        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.center()
            window.orderFrontRegardless()
            window.makeKeyAndOrderFront(nil)
            NSApp.arrangeInFront(nil)
        }
    }
}
