import SwiftUI
import Speech
import AVFoundation

/// Voice input bar component shown in the left column
/// Uses the glass box design while maintaining speech recognition functionality
struct VoiceBar: View {
    @StateObject var viewModel: VoiceBarViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Creates the glass-like appearance (same as GlassBox)
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.2),
                    lineWidth: 2
                )
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial.opacity(0.1))
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(
                    color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1),
                    radius: 10, x: 0, y: 5
                )
            
            // Content layout
            HStack(spacing: 15) {
                
                // Transcript text
                Text(viewModel.transcript)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .font(.system(size: 18, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: viewModel.isListening ? "waveform.circle.fill" : "mic.circle.fill")
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .font(.system(size: 24))
                    .onTapGesture {
                        if viewModel.isListening {
                            viewModel.stopListening()
                        } else {
                            viewModel.startListening()
                        }
                    }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(height: 80)
    }
}

// Speech recognizer class for macOS - without AVAudioSession
class SpeechRecognizer: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    private let speechRecognizer: SFSpeechRecognizer
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override init() {
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) else {
            fatalError("Speech recognizer locale not supported")
        }
        self.speechRecognizer = recognizer
        super.init()
        speechRecognizer.delegate = self
    }
    
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
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
    
    func startRecording(completion: @escaping (Result<String, Error>) -> Void) {
        // Cancel any existing recognition tasks
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // Create and configure the speech recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            completion(.failure(NSError(domain: "SpeechRecognizerError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])))
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Start recognition
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // Pass the recognized text to our completion handler
                completion(.success(result.bestTranscription.formattedString))
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                // Stop audio if there's an error or we've finished
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }
        
        // Configure the microphone input
        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // Start the audio engine
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            completion(.success(""))
        } catch {
            completion(.failure(error))
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
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

#Preview {
    VoiceBar(viewModel: VoiceBarViewModel())
}
