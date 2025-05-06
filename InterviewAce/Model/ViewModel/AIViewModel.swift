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

    // New properties for enhanced response format
    @Published var parsedResponse: AIResponseModel?
    @Published var selectedCodeCard: AIResponseModel.CodeCard?

    private var geminiService = GeminiService()
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupGeminiObservers()
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
                    self.selectedCodeCard = nil
                case .processing:
                    self.state = .processing
                    self.isProcessing = true
                case .success(let text):
                    self.response = text
                    self.state = .success(text)
                    self.isProcessing = false

                    print("AIViewModel: Processing successful response: \(text.prefix(100))...")

                    // Try to parse the response as JSON
                    self.parsedResponse = AIResponseModel.parse(from: text)

                    // If parsing failed, create a simple text-only response
                    if self.parsedResponse == nil {
                        print("AIViewModel: JSON parsing failed, creating text-only response")
                        self.parsedResponse = AIResponseModel(text: text, code_cards: nil)
                    } else {
                        print("AIViewModel: Successfully parsed response")

                        // Log the code cards
                        if let codeCards = self.parsedResponse?.code_cards, !codeCards.isEmpty {
                            print("AIViewModel: Found \(codeCards.count) code cards:")
                            for (index, card) in codeCards.enumerated() {
                                print("  Card \(index+1): \(card.title) (\(card.language)) - \(card.code.count) chars")
                            }
                        } else {
                            print("AIViewModel: No code cards found in parsed response")
                        }
                    }

                    // Reset selected code card
                    self.selectedCodeCard = nil

                    // If there are code cards, select the first one automatically
                    if let codeCards = self.parsedResponse?.code_cards, !codeCards.isEmpty {
                        let firstCard = codeCards.first!
                        print("AIViewModel: Auto-selecting first code card: \(firstCard.title)")

                        // Use a short delay to ensure the UI has time to update
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            print("AIViewModel: Setting selected code card to: \(firstCard.title)")
                            self.selectedCodeCard = firstCard
                        }
                    } else {
                        print("AIViewModel: No code cards to select")
                    }
                case .error(let errorMessage):
                    self.state = .error(errorMessage)
                    self.isProcessing = false
                    self.parsedResponse = nil
                    self.selectedCodeCard = nil
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

    /// Select a code card to display in the OutputCodeView
    func selectCodeCard(_ codeCard: AIResponseModel.CodeCard?) {
        print("AIViewModel: Selecting code card: \(String(describing: codeCard?.title))")

        // Log the code content if available
        if let card = codeCard {
            print("AIViewModel: Card code content: \(card.code.prefix(100))...")
            print("AIViewModel: Card code length: \(card.code.count) chars")
        }

        // First set to nil to ensure the change is detected
        self.selectedCodeCard = nil

        // Then set the new card after a very short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            print("AIViewModel: Setting selected code card after delay")
            self.selectedCodeCard = codeCard

            // Log the selected card details
            if let card = codeCard {
                print("AIViewModel: Selected card set to \(card.title) with \(card.code.count) chars of code")

                // Post a notification to inform any interested parties
                NotificationCenter.default.post(
                    name: Notification.Name("CodeCardSelected"),
                    object: nil,
                    userInfo: ["cardTitle": card.title, "codeLength": card.code.count]
                )
            }
        }
    }
}
