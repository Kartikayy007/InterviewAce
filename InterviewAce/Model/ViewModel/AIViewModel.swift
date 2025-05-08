import SwiftUI
import FirebaseVertexAI
import FirebaseCore
import Combine
import MarkdownUI

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

    // Property for enhanced response format
    @Published var parsedResponse: AIResponseModel?

    // Property for MarkdownUI content
    @Published var markdownContent: MarkdownContent?

    private var geminiService = GeminiService()
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupGeminiObservers()
        setupModelChangeObserver()
    }

    private func setupModelChangeObserver() {
        // Listen for model change notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ModelChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }

            if let modelName = notification.userInfo?["modelName"] as? String {
                // Set a temporary message to inform the user about the model change
                let previousState = self.state
                self.state = .success("Model changed to: \(modelName)")

                // Restore previous state after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.state = previousState
                }
            }
        }
    }

    private func setupGeminiObservers() {
        // Observe state changes in the GeminiService
        geminiService.$state
            .sink { [weak self] state in
                guard let self = self else { return }

                switch state {
                case .idle:
                    self.state = .idle
                    self.isProcessing = false
                    self.parsedResponse = nil
                    self.markdownContent = nil
                case .processing:
                    self.state = .processing
                    self.isProcessing = true
                case .success(let text):
                    self.response = text
                    self.state = .success(text)
                    self.isProcessing = false

                    print("AIViewModel: Processing successful response: \(text.prefix(100))...")

                    // We're receiving plain markdown text
                    print("AIViewModel: Processing markdown response")

                    // Create a response model with the markdown text
                    // This will automatically extract code blocks from the markdown
                    self.parsedResponse = AIResponseModel(text: text, code_cards: nil)

                    // Create MarkdownContent for MarkdownUI
                    self.markdownContent = MarkdownContent(text)
                case .error(let errorMessage):
                    self.state = .error(errorMessage)
                    self.isProcessing = false
                    self.parsedResponse = nil
                    self.markdownContent = nil
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

    deinit {
        // Remove notification observer when this object is deallocated
        NotificationCenter.default.removeObserver(self)
    }
}
