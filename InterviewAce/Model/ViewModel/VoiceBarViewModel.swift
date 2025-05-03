//
//  VoiceBarViewModel.swift
//  InterviewAce
//
//  Created by kartikay on 01/05/25.
//

import Foundation
import AVFoundation

class VoiceBarViewModel: ObservableObject {
    @Published var transcript: String = "Ready to transcribe"
    @Published var isListening = false
    @Published var isSystemAudioMode = false
    
    private let speechRecognizer = SpeechRecognizer()
    private let systemAudioCapture = SystemAudioCapture()

    init() {
        speechRecognizer.requestAuthorization()
    }
    
    func setAudioSource(isSystemAudio: Bool) {
        self.isSystemAudioMode = isSystemAudio
        if isSystemAudio {
            transcript = "Ready for system audio"
        } else {
            transcript = "Ready for microphone"
        }
    }

    func startListening() {
        print("Starting to listen...")
        transcript = "Listening..."
        isListening = true
        
        if isSystemAudioMode {
            // Start capturing system audio
            systemAudioCapture.startCapture { [weak self] buffer in
                // Send the audio buffer to speech recognizer
                self?.speechRecognizer.processAudioBuffer(buffer)
                print("Processing audio buffer...")
            }
            
            // Handle transcription updates
            speechRecognizer.onTranscription = { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let text):
                        print("Transcription update: \(text)")
                        self?.transcript = text.isEmpty ? "Listening..." : text
                    case .failure(let error):
                        print("Transcription error: \(error.localizedDescription)")
                        self?.transcript = "Error: \(error.localizedDescription)"
                        self?.stopListening()
                    }
                }
            }
        } else {
            // Use the existing microphone-based recognition
            speechRecognizer.startRecording { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let text):
                        print("Microphone transcription: \(text)")
                        self?.transcript = text.isEmpty ? "Listening..." : text
                    case .failure(let error):
                        print("Microphone error: \(error.localizedDescription)")
                        self?.transcript = "Error: \(error.localizedDescription)"
                        self?.stopListening()
                    }
                }
            }
        }
    }

    func stopListening() {
        if isSystemAudioMode {
            systemAudioCapture.stopCapture()
        } else {
            speechRecognizer.stopRecording()
        }
        isListening = false

        if transcript == "Listening..." {
            transcript = "Ready to transcribe"
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self = self else { return }
            if !(self.isListening) {
                self.transcript = "Ready to transcribe"
            }
        }
    }

    func toggleListening() {
        isListening ? stopListening() : startListening()
    }
}
