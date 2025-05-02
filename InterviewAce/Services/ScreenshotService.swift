//
//  ScreenshotService.swift
//  InterviewAce
//
//  Created by kartikay on 02/05/25.
//

import Foundation
import ScreenCaptureKit
import AVFoundation
import Cocoa

// Define notification names
extension Notification.Name {
    static let screenshotTaken = Notification.Name("ScreenshotTakenNotification")
    static let screenshotPermissionError = Notification.Name("ScreenshotPermissionErrorNotification")
}

class ScreenshotService {
    // Track if we've already shown the permission dialog
    private var hasShownPermissionDialog = false

    // Track if a capture is in progress to prevent multiple captures
    private var captureInProgress = false

    // Take a screenshot using ScreenCaptureKit
    func captureScreen() {
        // Prevent multiple simultaneous captures
        guard !captureInProgress else {
            print("⚠️ Screenshot capture already in progress")
            return
        }

        captureInProgress = true

        // Use Task to handle async operations
        Task {
            do {
                // Check for permission by trying to get shareable content
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)

                // Get the main display
                guard let display = content.displays.first else {
                    print("❌ No display found")
                    captureInProgress = false
                    return
                }

                // Create a filter for the display
                let filter = SCContentFilter(display: display, excludingWindows: [])

                // Configure the stream
                let config = SCStreamConfiguration()
                config.width = display.width * 2  // For Retina displays
                config.height = display.height * 2  // For Retina displays
                config.minimumFrameInterval = CMTime(value: 1, timescale: 1)
                config.queueDepth = 1

                // Create a stream
                let stream = SCStream(filter: filter, configuration: config, delegate: nil)

                // Create a screenshot handler
                let handler = ScreenshotHandler { [weak self] image in
                    self?.saveScreenshot(image)
                    self?.captureInProgress = false
                }

                // Add the output handler to the stream
                try stream.addStreamOutput(handler, type: .screen, sampleHandlerQueue: .main)

                // Start the capture
                try await stream.startCapture()

            } catch {
                print("❌ Screenshot capture failed: \(error.localizedDescription)")

                // Check if this is a permission error
                if error.localizedDescription.contains("permission") ||
                   error.localizedDescription.contains("denied") ||
                   error.localizedDescription.contains("authorize") {
                    handlePermissionError()
                }

                captureInProgress = false
            }
        }
    }

    // Handle permission errors
    private func handlePermissionError() {
        // Only post the notification once to avoid multiple dialogs
        if !hasShownPermissionDialog {
            hasShownPermissionDialog = true

            print("❌ Screen capture permission not granted")

            // Post notification for the app delegate to handle
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .screenshotPermissionError,
                    object: nil
                )
            }
        }
    }

    // Save the screenshot to the desktop
    private func saveScreenshot(_ image: NSImage) {
        // Create a filename with timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())

        // Get desktop path
        guard let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first else {
            print("❌ Could not access desktop directory")
            return
        }

        // Create file URL
        let fileURL = desktop.appendingPathComponent("interviewace_screenshot_\(timestamp).png")

        // Convert NSImage to PNG data
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            print("❌ Failed to convert image to PNG")
            return
        }

        // Write to file
        do {
            try pngData.write(to: fileURL)
            print("📸 Screenshot saved to: \(fileURL.path)")

            // Post notification that screenshot was taken
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .screenshotTaken,
                    object: nil,
                    userInfo: ["fileURL": fileURL]
                )
            }
        } catch {
            print("❌ Failed to save screenshot: \(error.localizedDescription)")
        }
    }

    // Reset the permission dialog flag (useful if the app is reactivated)
    func resetPermissionDialogFlag() {
        hasShownPermissionDialog = false
    }
}

// Custom class to handle screenshot capture
class ScreenshotHandler: NSObject, SCStreamOutput {
    private let completionHandler: (NSImage) -> Void

    init(completionHandler: @escaping (NSImage) -> Void) {
        self.completionHandler = completionHandler
        super.init()
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        // Convert the pixel buffer to an NSImage
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let rep = NSCIImageRep(ciImage: ciImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)

        // Call the completion handler with the image
        completionHandler(nsImage)

        // Stop the stream after capturing one frame
        Task {
            do {
                try await stream.stopCapture()
            } catch {
                print("❌ Failed to stop screen capture: \(error.localizedDescription)")
            }
        }
    }
}
