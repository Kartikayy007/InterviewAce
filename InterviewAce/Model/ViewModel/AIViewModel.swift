import SwiftUI
import FirebaseVertexAI
import FirebaseCore
import Combine

enum AIProcessingState {
    case idle
    case processing
    case success(String)
    case error(String)
}

class AIViewModel: ObservableObject {
    @Published var state: AIProcessingState = .idle
    @Published var response: String = ""
    @Published var isProcessing: Bool = false
    
    private var geminiService = GeminiService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupGeminiObservers()
    }
    
    private func setupGeminiObservers() {
        print("AIViewModel: Setting up Gemini service observers")
        
        // Observe state changes in the GeminiService
        geminiService.$state
            .sink { [weak self] state in
                guard let self = self else { return }
                
                switch state {
                case .idle:
                    self.state = .idle
                    self.isProcessing = false
                case .processing:
                    self.state = .processing
                    self.isProcessing = true
                case .success(let text):
                    self.response = text
                    self.state = .success(text)
                    self.isProcessing = false
                case .error(let errorMessage):
                    self.state = .error(errorMessage)
                    self.isProcessing = false
                }
            }
            .store(in: &cancellables)
    }
    
    func processQuery(_ query: String) {
        guard !query.isEmpty else {
            print("AIViewModel: Empty query, not sending request")
            return
        }
        
        print("AIViewModel: Processing query: \(query)")
        geminiService.processQuery(query)
    }
    
    func processTranscript(from voiceViewModel: VoiceBarViewModel) {
        let transcript = voiceViewModel.transcript
        
        // Don't process if the transcript is just the default message or if we're already processing
        guard transcript != "Ready to transcribe" && 
              transcript != "Listening..." && 
              transcript != "Ready for microphone" &&
              transcript != "Ready for system audio" &&
              !isProcessing else {
            return
        }
        
        processQuery(transcript)
    }
    
    func cancelRequest() {
        print("AIViewModel: Cancelling request")
        geminiService.cancelRequest()
    }
}
