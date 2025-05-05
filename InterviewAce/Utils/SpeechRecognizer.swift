import Foundation
import Speech
import AVFoundation
import Combine

// Using AudioCap's SpeechRecognizer implementation with minimal changes for InterviewAce
final class SpeechRecognizer: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    @Published var transcribedText = ""
    @Published var isTranscribing = false
    @Published var errorMessage: String? = nil
    
    private let speechRecognizer: SFSpeechRecognizer
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var onTranscription: ((Result<String, Error>) -> Void)?
    
    override init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
        super.init()
        speechRecognizer.delegate = self
        checkPermissions()
    }
    
    private func checkPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.errorMessage = nil
                case .denied:
                    self.errorMessage = "Speech recognition permission denied"
                case .restricted:
                    self.errorMessage = "Speech recognition is restricted"
                case .notDetermined:
                    self.errorMessage = "Speech recognition permission not determined"
                @unknown default:
                    self.errorMessage = "Unknown speech recognition permission status"
                }
            }
        }
    }
    
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied:
                    print("Speech recognition authorization denied")
                case .restricted:
                    print("Speech recognition restricted on this device")
                case .notDetermined:
                    print("Speech recognition not yet authorized")
                @unknown default:
                    print("Unknown authorization status")
                }
            }
        }
    }
    
    func startTranscribing(format: AVAudioFormat) {
        guard !isTranscribing else {
            print("SpeechRecognizer: Already transcribing")
            return
        }
        
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            errorMessage = "Speech recognition not authorized"
            return
        }
        
        do {
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            
            guard let recognitionRequest = recognitionRequest else {
                throw NSError(domain: "SpeechRecognizerErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not create speech recognition request"])
            }
            
            recognitionRequest.shouldReportPartialResults = true
            
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Recognition error: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    self.stopTranscribing()
                    return
                }
                
                if let result = result {
                    DispatchQueue.main.async {
                        self.transcribedText = result.bestTranscription.formattedString
                        // Also notify through the callback
                        self.onTranscription?(.success(result.bestTranscription.formattedString))
                    }
                }
            }
            
            isTranscribing = true
            errorMessage = nil
            
        } catch {
            print("Failed to start transcription: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard isTranscribing, let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.append(buffer)
    }
    
    func stopTranscribing() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        isTranscribing = false
    }
    
    // SFSpeechRecognizerDelegate method
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            print("Speech recognition available")
        } else {
            print("Speech recognition unavailable")
        }
    }
}