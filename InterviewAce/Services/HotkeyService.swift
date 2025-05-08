//
//  HotkeyService.swift
//  InterviewAce
//
//  Created by kartikay on 01/05/25.
//

import HotKey
import Cocoa

class HotkeyService {
    private var hotkeys: [HotKey] = []

    private var overlayManager: OverlayWindowManager
    private var voiceViewModel: VoiceBarViewModel
    private var minimizeViewModel: MinimizeViewModel
    
    private var screenshotService: ScreenshotService?

    init(overlayManager: OverlayWindowManager,
         voiceViewModel: VoiceBarViewModel,
         screenshotService: ScreenshotService?,
         minimizeViewModel: MinimizeViewModel) {

        self.overlayManager = overlayManager
        self.voiceViewModel = voiceViewModel
        self.screenshotService = screenshotService
        self.minimizeViewModel = minimizeViewModel

        setupToggleShortcut()
        setupHorizontalMovementShortcuts()
        setupFastHorizontalMovementShortcuts()
        setupHorizontalPositionShortcuts()
        setupCenterShortcut()
        setupVoiceShortcut()
        setupScreenshotShortcut()
        setupMinimizeShortcut()
    }

    private func setupToggleShortcut() {
        let hotkey = HotKey(key: .a, modifiers: [.command, .shift])
        hotkey.keyDownHandler = { [weak self] in
            self?.overlayManager.toggleVisibility()
        }
        hotkeys.append(hotkey)
        print("✅ Registered shortcut: ⌘⇧A - Toggle overlay")
    }

    private func setupHorizontalMovementShortcuts() {
        // Only left and right arrow keys for horizontal movement
        let left = HotKey(key: .leftArrow, modifiers: [.option])
        left.keyDownHandler = { [weak self] in
            self?.overlayManager.moveWindow(xDelta: -self!.overlayManager.moveStep, yDelta: 0)
        }

        let right = HotKey(key: .rightArrow, modifiers: [.option])
        right.keyDownHandler = { [weak self] in
            self?.overlayManager.moveWindow(xDelta: self!.overlayManager.moveStep, yDelta: 0)
        }

        hotkeys += [left, right]
        print("✅ Registered shortcut: ⌥ + Left/Right Arrows - Move overlay horizontally")
    }

    private func setupFastHorizontalMovementShortcuts() {
        // Only left and right arrow keys for fast horizontal movement
        let left = HotKey(key: .leftArrow, modifiers: [.option, .shift])
        left.keyDownHandler = { [weak self] in
            self?.overlayManager.moveWindow(xDelta: -self!.overlayManager.fastMoveStep, yDelta: 0)
        }

        let right = HotKey(key: .rightArrow, modifiers: [.option, .shift])
        right.keyDownHandler = { [weak self] in
            self?.overlayManager.moveWindow(xDelta: self!.overlayManager.fastMoveStep, yDelta: 0)
        }

        hotkeys += [left, right]
        print("✅ Registered shortcut: ⌥⇧ + Left/Right Arrows - Fast move overlay horizontally")
    }

    private func setupHorizontalPositionShortcuts() {
        // Just use 1 for left side and 2 for right side of the screen
        let left = HotKey(key: .one, modifiers: [.control])
        left.keyDownHandler = { [weak self] in
            self?.overlayManager.moveWindowToCorner(corner: .topLeft)
        }

        let right = HotKey(key: .two, modifiers: [.control])
        right.keyDownHandler = { [weak self] in
            self?.overlayManager.moveWindowToCorner(corner: .topRight)
        }

        hotkeys += [left, right]
        print("✅ Registered shortcuts: ⌃1, ⌃2 - Move to left/right side")
    }

    private func setupCenterShortcut() {
        let center = HotKey(key: .space, modifiers: [.control])
        center.keyDownHandler = { [weak self] in
            self?.overlayManager.centerWindow()
        }
        hotkeys.append(center)
        print("✅ Registered shortcut: ⌃Space - Center overlay horizontally")
    }

    private func setupVoiceShortcut() {
        let voiceHotkey = HotKey(key: .v, modifiers: [.command, .shift])
        voiceHotkey.keyDownHandler = { [weak self] in
            self?.voiceViewModel.toggleListening()
        }
        hotkeys.append(voiceHotkey)
        print("✅ Registered shortcut: ⌘⇧V - Toggle voice listening")
    }

    private func setupScreenshotShortcut() {
        let screenshotHotkey = HotKey(key: .s, modifiers: [.command, .shift])
        screenshotHotkey.keyDownHandler = { [weak self] in
            // Call the screenshot service
            self?.screenshotService?.captureScreen()
        }
        hotkeys.append(screenshotHotkey)
        print("✅ Registered shortcut: ⌘⇧S - Take screenshot")
    }
    
    private func setupMinimizeShortcut() {
        let minimizeHotkey = HotKey(key: .m, modifiers: [.command, .shift])
        minimizeHotkey.keyDownHandler = { [weak self] in
            self?.minimizeViewModel.toggle()
        }
        hotkeys.append(minimizeHotkey)
        print("✅ Registered shortcut: ⌘⇧M - Toggle minimize")
    }
}
