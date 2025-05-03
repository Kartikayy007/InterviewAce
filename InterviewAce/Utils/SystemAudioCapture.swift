import Foundation
import AVFoundation

class SystemAudioCapture {
    private var audioEngine = AVAudioEngine()
    private var isCaptureActive = false
    
    func startCapture(processingCallback: @escaping (AVAudioPCMBuffer) -> Void) {
        // Check if already capturing
        guard !isCaptureActive else {
            print("SystemAudioCapture: Already capturing")
            return
        }
        
        print("SystemAudioCapture: Starting system audio capture")
        
        // Get the output node (system audio)
        let outputNode = audioEngine.outputNode
        
        // Configure the tap on the output node to get system audio
        let recordingFormat = outputNode.outputFormat(forBus: 0)
        print("SystemAudioCapture: Recording format: \(recordingFormat)")
        
        outputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, time in
            print("SystemAudioCapture: Received audio buffer")
            processingCallback(buffer)
        }
        
        // Start the audio engine
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isCaptureActive = true
            print("SystemAudioCapture: System audio capture started successfully")
        } catch {
            print("SystemAudioCapture: Failed to start system audio capture: \(error.localizedDescription)")
        }
    }
    
    func stopCapture() {
        guard isCaptureActive else {
            print("SystemAudioCapture: Already stopped")
            return
        }
        
        print("SystemAudioCapture: Stopping system audio capture")
        
        audioEngine.outputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isCaptureActive = false
        print("SystemAudioCapture: System audio capture stopped")
    }
}