import Foundation
import AVFoundation
import CoreAudio
import AudioToolbox

// Extension to make strings throwable as errors
extension String: LocalizedError {
    public var errorDescription: String? { self }
}

// Required extension from CoreAudioUtils.swift in AudioCap
extension AudioObjectID {
    /// Convenience for `kAudioObjectSystemObject`.
    static let system = AudioObjectID(kAudioObjectSystemObject)
    /// Convenience for `kAudioObjectUnknown`.
    static let unknown = kAudioObjectUnknown

    /// `true` if this object has the value of `kAudioObjectUnknown`.
    var isUnknown: Bool { self == .unknown }

    /// `false` if this object has the value of `kAudioObjectUnknown`.
    var isValid: Bool { !isUnknown }

    /// Reads `kAudioHardwarePropertyProcessObjectList` from the system object.
    static func readProcessList() throws -> [AudioObjectID] {
        try AudioObjectID.system.readProcessList()
    }

    /// Reads `kAudioHardwarePropertyProcessObjectList`.
    func readProcessList() throws -> [AudioObjectID] {
        guard self == .system else {
            throw "Only supported for the system object."
        }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyProcessObjectList,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        var err = AudioObjectGetPropertyDataSize(self, &address, 0, nil, &dataSize)
        guard err == noErr else {
            throw "Error reading data size for process list: \(err)"
        }

        var value = [AudioObjectID](repeating: .unknown, count: Int(dataSize) / MemoryLayout<AudioObjectID>.size)
        err = AudioObjectGetPropertyData(self, &address, 0, nil, &dataSize, &value)
        guard err == noErr else {
            throw "Error reading process list: \(err)"
        }

        return value
    }

    /// Reads if a process is running audio
    func readProcessIsRunning() -> Bool {
        do {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioProcessPropertyIsRunning,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )

            var value: UInt32 = 0
            var dataSize = UInt32(MemoryLayout<UInt32>.size)

            let err = AudioObjectGetPropertyData(self, &address, 0, nil, &dataSize, &value)
            return err == noErr && value != 0
        } catch {
            return false
        }
    }
}

/// A class that captures system-wide audio using CoreAudio's process tap API.
/// This implementation captures audio from all running processes on the system.
class SystemAudioCapture {
    private var isCaptureActive = false

    // For CoreAudio process tap - directly from AudioCap
    private var processTapID = AudioObjectID.unknown
    private var aggregateDeviceID = AudioObjectID.unknown
    private var deviceProcID: AudioDeviceIOProcID?
    private var tapStreamDescription: AudioStreamBasicDescription?
    private var audioCaptureFormat: AVAudioFormat?

    // For audio buffer processing
    private var bufferProcessingCallback: ((AVAudioPCMBuffer) -> Void)?

    // For monitoring
    private var bufferCounter = 0
    private var lastLogTime: TimeInterval = 0

    deinit {
        print("SystemAudioCapture being deallocated")
        stopCapture()
    }

    /// Start capturing system-wide audio
    /// - Parameter processingCallback: Callback that will be called with each audio buffer
    func startCapture(processingCallback: @escaping (AVAudioPCMBuffer) -> Void) {
        // Check if already capturing
        guard !isCaptureActive else {
            print("SystemAudioCapture: Already capturing")
            return
        }

        print("SystemAudioCapture: Starting system-wide audio capture")

        self.bufferProcessingCallback = processingCallback

        // Only support macOS 14.4+
        if #available(macOS 14.4, *) {
            print("SystemAudioCapture: Using system-wide audio capture with process tap API")
            startCaptureWithProcessTap()
        } else {
            print("SystemAudioCapture: ⚠️ This feature requires macOS 14.4 or later")
        }
    }

    func stopCapture() {
        guard isCaptureActive else {
            print("SystemAudioCapture: Already stopped")
            return
        }

        print("SystemAudioCapture: Stopping system audio capture")

        if #available(macOS 14.4, *) {
            stopCaptureWithProcessTap()
        }

        isCaptureActive = false
        bufferProcessingCallback = nil
        print("SystemAudioCapture: System audio capture stopped")
    }

    // MARK: - Process Tap Implementation (macOS 14.4+) - Directly from AudioCap

    @available(macOS 14.4, *)
    private func startCaptureWithProcessTap() {
        do {
            // Get system audio object ID
            let systemObjectID = AudioObjectID.system

            // Get all process IDs for system-wide audio capture
            let allProcessIDs = try AudioObjectID.readProcessList()
            print("SystemAudioCapture: Found \(allProcessIDs.count) audio processes")

            // Create the process tap for system-wide audio
            let tapDescription = CATapDescription(stereoMixdownOfProcesses: allProcessIDs)
            tapDescription.uuid = UUID()
            tapDescription.muteBehavior = .unmuted

            var tapID = AudioObjectID.unknown
            var err = AudioHardwareCreateProcessTap(tapDescription, &tapID)

            guard err == noErr else {
                throw "Failed to create process tap: \(err)"
            }

            print("SystemAudioCapture: Created process tap #\(tapID)")
            self.processTapID = tapID

            // Get default output device
            var defaultOutputDevice: AudioDeviceID = 0
            var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
            var outputDeviceAddress = AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )

            err = AudioObjectGetPropertyData(
                systemObjectID,
                &outputDeviceAddress,
                0,
                nil,
                &propertySize,
                &defaultOutputDevice
            )

            guard err == noErr else {
                throw "Error getting default output device: \(err)"
            }

            // Get device UID
            var uidAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceUID,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )

            var cfUID: CFString?
            propertySize = UInt32(MemoryLayout<CFString?>.size)

            err = AudioObjectGetPropertyData(
                defaultOutputDevice,
                &uidAddress,
                0,
                nil,
                &propertySize,
                &cfUID
            )

            guard err == noErr, let deviceUID = cfUID as String? else {
                throw "Failed to get device UID: \(err)"
            }

            // Read the tap stream description
            var formatAddress = AudioObjectPropertyAddress(
                mSelector: kAudioTapPropertyFormat,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )

            var streamDescription = AudioStreamBasicDescription()
            propertySize = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)

            err = AudioObjectGetPropertyData(
                tapID,
                &formatAddress,
                0,
                nil,
                &propertySize,
                &streamDescription
            )

            guard err == noErr else {
                throw "Failed to get tap stream format: \(err)"
            }

            self.tapStreamDescription = streamDescription

            // Create aggregate device that connects the system output with our tap
            let aggregateUID = UUID().uuidString

            // Directly using AudioCap's aggregateDescription structure
            let aggregateDescription: [String: Any] = [
                kAudioAggregateDeviceNameKey: "InterviewAce-SystemAudioTap",
                kAudioAggregateDeviceUIDKey: aggregateUID,
                kAudioAggregateDeviceMainSubDeviceKey: deviceUID,
                kAudioAggregateDeviceIsPrivateKey: true,
                kAudioAggregateDeviceIsStackedKey: false,
                kAudioAggregateDeviceTapAutoStartKey: true,
                kAudioAggregateDeviceSubDeviceListKey: [
                    [
                        kAudioSubDeviceUIDKey: deviceUID
                    ]
                ],
                kAudioAggregateDeviceTapListKey: [
                    [
                        kAudioSubTapDriftCompensationKey: true,
                        kAudioSubTapUIDKey: tapDescription.uuid.uuidString
                    ]
                ]
            ]

            // Create aggregate device - directly from AudioCap
            self.aggregateDeviceID = AudioObjectID.unknown
            err = AudioHardwareCreateAggregateDevice(aggregateDescription as CFDictionary, &aggregateDeviceID)

            guard err == noErr, aggregateDeviceID != AudioObjectID.unknown else {
                throw "Failed to create aggregate device: \(err)"
            }

            print("SystemAudioCapture: Created aggregate device #\(aggregateDeviceID)")

            // Create AVAudioFormat from the stream description
            guard let format = AVAudioFormat(streamDescription: &streamDescription) else {
                throw "Failed to create AVAudioFormat from stream description"
            }

            self.audioCaptureFormat = format

            print("SystemAudioCapture: Audio format - \(format.sampleRate) Hz, \(format.channelCount) channels")

            // Set up the IO proc to receive audio buffers - directly from AudioCap
            let queue = DispatchQueue(label: "com.interviewace.audiocapture", qos: .userInitiated)

            // Use the same AudioDeviceCreateIOProcIDWithBlock structure as AudioCap
            err = AudioDeviceCreateIOProcIDWithBlock(&deviceProcID, aggregateDeviceID, queue) {
                [weak self] (inNow, inInputData, inInputTime, outOutputData, inOutputTime) in

                guard let self = self,
                      let format = self.audioCaptureFormat else { return }

                // Create an AVAudioPCMBuffer from the provided buffer list
                guard let buffer = AVAudioPCMBuffer(pcmFormat: format, bufferListNoCopy: inInputData, deallocator: nil) else {
                    print("SystemAudioCapture: Failed to create PCM buffer")
                    return
                }

                // Process the audio buffer on the main thread
                DispatchQueue.main.async {
                    self.handleBufferReceived(buffer)
                }
            }

            guard err == noErr else {
                throw "Failed to create IO proc: \(err)"
            }

            // Start the audio device
            err = AudioDeviceStart(aggregateDeviceID, deviceProcID)

            guard err == noErr else {
                throw "Failed to start audio device: \(err)"
            }

            isCaptureActive = true
            bufferCounter = 0
            print("SystemAudioCapture: System audio capture started successfully")

        } catch {
            print("SystemAudioCapture: Error setting up audio capture: \(error.localizedDescription)")
            cleanup()
        }
    }

    @available(macOS 14.4, *)
    private func stopCaptureWithProcessTap() {
        cleanup()
    }

    private func cleanup() {
        // Stop and clean up the aggregate device
        if let deviceProcID = deviceProcID, aggregateDeviceID != AudioObjectID.unknown {
            let stopStatus = AudioDeviceStop(aggregateDeviceID, deviceProcID)
            if stopStatus != noErr {
                print("SystemAudioCapture: Error stopping audio device: \(stopStatus)")
            }

            let destroyStatus = AudioDeviceDestroyIOProcID(aggregateDeviceID, deviceProcID)
            if destroyStatus != noErr {
                print("SystemAudioCapture: Error destroying IO proc: \(destroyStatus)")
            }

            self.deviceProcID = nil
        }

        // Destroy the aggregate device
        if aggregateDeviceID != AudioObjectID.unknown {
            let status = AudioHardwareDestroyAggregateDevice(aggregateDeviceID)
            if status != noErr {
                print("SystemAudioCapture: Error destroying aggregate device: \(status)")
            }
            aggregateDeviceID = AudioObjectID.unknown
        }

        // Destroy the process tap
        if processTapID != AudioObjectID.unknown {
            let status = AudioHardwareDestroyProcessTap(processTapID)
            if status != noErr {
                print("SystemAudioCapture: Error destroying process tap: \(status)")
            }
            processTapID = AudioObjectID.unknown
        }

        // Clear the audio format
        audioCaptureFormat = nil
        tapStreamDescription = nil
    }

    /// Handle an audio buffer received from the system audio tap
    /// - Parameter buffer: The audio buffer containing captured audio data
    private func handleBufferReceived(_ buffer: AVAudioPCMBuffer) {
        bufferCounter += 1

        // Calculate peak levels for monitoring
        var peakValues = [Float](repeating: 0, count: Int(buffer.format.channelCount))

        // Calculate peak values for each channel
        for channel in 0..<Int(buffer.format.channelCount) {
            if let data = buffer.floatChannelData?[channel] {
                let frameCount = Int(buffer.frameLength)
                var peak: Float = 0

                for i in 0..<frameCount {
                    let sample = abs(data[i])
                    if sample > peak {
                        peak = sample
                    }
                }

                peakValues[channel] = peak
            }
        }

        // Log audio levels occasionally to avoid flooding console
        let currentTime = CACurrentMediaTime()
        if currentTime - lastLogTime > 3.0 {  // Log every 3 seconds
            let peakDB = peakValues.map { 20 * log10($0 > 0 ? $0 : 0.0000001) }
            let avgPeakDB = peakDB.reduce(0, +) / Float(peakDB.count)

            if avgPeakDB < -50 {
                print("SystemAudioCapture: Very low system audio level detected: \(String(format: "%.1f", avgPeakDB)) dB")
            } else {
                print("SystemAudioCapture: System audio buffer #\(bufferCounter): Peak level \(String(format: "%.1f", avgPeakDB)) dB")
            }

            lastLogTime = currentTime
        }

        // Call the user's processing callback
        bufferProcessingCallback?(buffer)
    }
}
