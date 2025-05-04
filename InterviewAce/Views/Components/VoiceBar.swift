import SwiftUI
import Speech
import AVFoundation

/// Voice input bar component shown in the left column
/// Uses the glass box design while maintaining speech recognition functionality
struct VoiceBar: View {
    @StateObject var viewModel: VoiceBarViewModel
    @State private var animateWaveform = false
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
                HStack(spacing: 8) {
                    Image(systemName: viewModel.isListening ? "waveform.circle.fill" : "mic.circle.fill")
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .font(.system(size: 24))
                    ShortcutKeyView(text: "⌘ ⇧ V")
                }
                .onTapGesture {
                    viewModel.isListening ? viewModel.stopListening() : viewModel.startListening()
                }

                Spacer()

                AnimatedTranscriptView(text: viewModel.transcript)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .font(.system(size: 18, weight: .medium))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(height: 80)
    }
}

/// Custom view that animates text changes with a fade-in from right and fade-out to left effect
struct AnimatedTranscriptView: View {
    let text: String
    @State private var previousWords: [String] = []
    @State private var newWord: String = ""
    @State private var showNewWord = false

    let maxLength: Int = 40

    var body: some View {
        HStack(spacing: 4) {
            Text(previousWords.joined(separator: " "))
                .lineLimit(1)
                .truncationMode(.head)

            if showNewWord {
                Text(newWord)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: showNewWord)
            }
        }
        .font(.system(size: 18, weight: .medium))
        .frame(maxHeight: .infinity)
        .offset(y: 1)
        .padding(.horizontal, 10)
        .mask(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0.01),
                    .init(color: .black, location: 0.5), // Increased from 0.1
                    .init(color: .black, location: 0.75), // Decreased from 0.9
                    .init(color: .clear, location: 1.0),
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .onChange(of: text) { _, newValue in
            let allWords = newValue.components(separatedBy: " ")
            guard let last = allWords.last else { return }

            if allWords != previousWords + [newWord] {
                withAnimation {
                    showNewWord = false
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let oldWords = Array(allWords.dropLast())
                    previousWords = oldWords
                    newWord = last
                    showNewWord = true
                }
            }
        }
        .onAppear {
            let words = text.components(separatedBy: " ")
            previousWords = Array(words.dropLast())
            newWord = words.last ?? ""
            showNewWord = true
        }
    }
}

// Speech recognizer class for macOS - without AVAudioSession
class SpeechRecognizer: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    private let speechRecognizer: SFSpeechRecognizer
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var onTranscription: ((Result<String, Error>) -> Void)?
    
    override init() {
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) else {
            fatalError("Speech recognizer locale not supported")
        }
        self.speechRecognizer = recognizer
        super.init()
        speechRecognizer.delegate = self
    }
    
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { (authStatus: SFSpeechRecognizerAuthorizationStatus) in
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
        print("SpeechRecognizer: Starting recording...")
        
        // Cancel any existing recognition tasks
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // Check if SFSpeechRecognizer is available
        if !speechRecognizer.isAvailable {
            print("SpeechRecognizer: Speech recognizer is not available!")
            completion(.failure(NSError(domain: "SpeechRecognizerError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer is not available"])))
            return
        }
        
        // Create and configure the speech recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            print("SpeechRecognizer: Unable to create recognition request")
            completion(.failure(NSError(domain: "SpeechRecognizerError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])))
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Start recognition
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { (result: SFSpeechRecognitionResult?, error: Error?) in
            var isFinal = false
            
            if let result = result {
                // Pass the recognized text to our completion handler
                print("SpeechRecognizer: Got result: \(result.bestTranscription.formattedString)")
                completion(.success(result.bestTranscription.formattedString))
                isFinal = result.isFinal
            }
            
            if let error = error {
                print("SpeechRecognizer: Error in recognition: \(error.localizedDescription)")
                completion(.failure(error))
            }
            
            if error != nil || isFinal {
                // Stop audio if there's an error or we've finished
                print("SpeechRecognizer: Stopping audio engine (error or final)")
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }
        
        // Configure the microphone input
        // For macOS, we generally don't need to use AVAudioSession since it's primarily for iOS
        // Instead, we just set up the audioEngine directly
        
        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        print("SpeechRecognizer: Recording format: \(recordingFormat)")
        
        print("SpeechRecognizer: Installing tap on input node")
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, _: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        // Start the audio engine
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            print("SpeechRecognizer: Audio engine started successfully")
            completion(.success(""))
        } catch {
            print("SpeechRecognizer: Audio engine start error: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
    }
    
    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Create recognition request if needed
        if recognitionRequest == nil {
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            
            guard let recognitionRequest = recognitionRequest else { return }
            recognitionRequest.shouldReportPartialResults = true
            
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] (result: SFSpeechRecognitionResult?, error: Error?) in
                guard let self = self else { return }
                
                var isFinal = false
                
                if let result = result {
                    // Pass transcription back through the callback
                    self.onTranscription?(.success(result.bestTranscription.formattedString))
                    isFinal = result.isFinal
                }
                
                if error != nil || isFinal {
                    // Clean up on error or completion
                    self.audioEngine.stop()
                    self.audioEngine.inputNode.removeTap(onBus: 0)
                    
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                    
                    if let error = error {
                        self.onTranscription?(.failure(error))
                    }
                }
            }
        }
        
        // Append the buffer to the recognition request
        recognitionRequest?.append(buffer)
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
