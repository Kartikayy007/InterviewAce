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
        setupArrowKeyShortcuts()
        setupFastMovementShortcuts()
        setupCornerShortcuts()
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

    private func setupArrowKeyShortcuts() {
        let left = HotKey(key: .leftArrow, modifiers: [.option])
        left.keyDownHandler = { [weak self] in
            self?.overlayManager.moveWindow(xDelta: -self!.overlayManager.moveStep, yDelta: 0)
        }

        let right = HotKey(key: .rightArrow, modifiers: [.option])
        right.keyDownHandler = { [weak self] in
            self?.overlayManager.moveWindow(xDelta: self!.overlayManager.moveStep, yDelta: 0)
        }

        let up = HotKey(key: .upArrow, modifiers: [.option])
        up.keyDownHandler = { [weak self] in
            self?.overlayManager.moveWindow(xDelta: 0, yDelta: self!.overlayManager.moveStep)
        }

        let down = HotKey(key: .downArrow, modifiers: [.option])
        down.keyDownHandler = { [weak self] in
            self?.overlayManager.moveWindow(xDelta: 0, yDelta: -self!.overlayManager.moveStep)
        }

        hotkeys += [left, right, up, down]
        print("✅ Registered shortcut: ⌥ + Arrow keys - Move overlay")
    }

    private func setupFastMovementShortcuts() {
        let left = HotKey(key: .leftArrow, modifiers: [.option, .shift])
        left.keyDownHandler = { [weak self] in
            self?.overlayManager.moveWindow(xDelta: -self!.overlayManager.fastMoveStep, yDelta: 0)
        }

        let right = HotKey(key: .rightArrow, modifiers: [.option, .shift])
        right.keyDownHandler = { [weak self] in
            self?.overlayManager.moveWindow(xDelta: self!.overlayManager.fastMoveStep, yDelta: 0)
        }

        let up = HotKey(key: .upArrow, modifiers: [.option, .shift])
        up.keyDownHandler = { [weak self] in
            self?.overlayManager.moveWindow(xDelta: 0, yDelta: self!.overlayManager.fastMoveStep)
        }

        let down = HotKey(key: .downArrow, modifiers: [.option, .shift])
        down.keyDownHandler = { [weak self] in
            self?.overlayManager.moveWindow(xDelta: 0, yDelta: -self!.overlayManager.fastMoveStep)
        }

        hotkeys += [left, right, up, down]
        print("✅ Registered shortcut: ⌥⇧ + Arrow keys - Fast move overlay")
    }

    private func setupCornerShortcuts() {
        let topLeft = HotKey(key: .one, modifiers: [.control])
        topLeft.keyDownHandler = { [weak self] in
            self?.overlayManager.moveWindowToCorner(corner: .topLeft)
        }

        let topRight = HotKey(key: .two, modifiers: [.control])
        topRight.keyDownHandler = { [weak self] in
            self?.overlayManager.moveWindowToCorner(corner: .topRight)
        }

        let bottomLeft = HotKey(key: .three, modifiers: [.control])
        bottomLeft.keyDownHandler = { [weak self] in
            self?.overlayManager.moveWindowToCorner(corner: .bottomLeft)
        }

        let bottomRight = HotKey(key: .four, modifiers: [.control])
        bottomRight.keyDownHandler = { [weak self] in
            self?.overlayManager.moveWindowToCorner(corner: .bottomRight)
        }

        hotkeys += [topLeft, topRight, bottomLeft, bottomRight]
        print("✅ Registered shortcuts: ⌃1, ⌃2, ⌃3, ⌃4 - Move to corners")
    }

    private func setupCenterShortcut() {
        let center = HotKey(key: .space, modifiers: [.control])
        center.keyDownHandler = { [weak self] in
            self?.overlayManager.centerWindow()
        }
        hotkeys.append(center)
        print("✅ Registered shortcut: ⌃Space - Center overlay")
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
    }
}
