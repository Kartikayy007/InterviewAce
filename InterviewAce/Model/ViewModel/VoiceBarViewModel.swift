//
//  VoiceBarViewModel.swift
//  InterviewAce
//
//  Created by kartikay on 01/05/25.
//

import Foundation

class VoiceBarViewModel: ObservableObject {
    @Published var transcript: String = "Speak"
    @Published var isListening = false

    private let speechRecognizer = SpeechRecognizer()

    init() {
        speechRecognizer.requestAuthorization()
    }

    func startListening() {
        transcript = "Listening..."
        isListening = true

        speechRecognizer.startRecording { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let text):
                    self?.transcript = text.isEmpty ? "Listening..." : text
                case .failure(let error):
                    self?.transcript = "Error: \(error.localizedDescription)"
                    self?.stopListening()
                }
            }
        }
    }

    func stopListening() {
        speechRecognizer.stopRecording()
        isListening = false

        if transcript == "Listening..." {
            transcript = "Talk to Siri"
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if !(self.isListening) {
                self.transcript = "Talk to Siri"
            }
        }
    }

    func toggleListening() {
        isListening ? stopListening() : startListening()
    }
}
