//
//  VoiceBarViewModel.swift
//  InterviewAce
//
//  Created by kartikay on 01/05/25.
//

import Foundation
import AVFoundation
import Combine
import Speech

class VoiceBarViewModel: ObservableObject {
    @Published var transcript: String = "Ready to transcribe"
    @Published var isListening = false
    @Published var audioPermissionStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    // Services for audio capture and transcription
    private var systemAudioCapture = SystemAudioCapture()
    private var speechRecognizer = SpeechRecognizer()
    
    var cancellables = Set<AnyCancellable>() // For Combine subscriptions

    init() {
        checkPermissions()
        setupTranscriptionUpdates()
    }
    
    private func setupTranscriptionUpdates() {
        // Connect the speech recognizer's transcribed text to our transcript
        speechRecognizer.$transcribedText
            .receive(on: RunLoop.main)
            .sink { [weak self] newText in
                guard let self = self, !newText.isEmpty else { return }
                self.transcript = newText
            }
            .store(in: &cancellables)
        
        // Handle errors from speech recognizer
        speechRecognizer.$errorMessage
            .receive(on: RunLoop.main)
            .sink { [weak self] errorMessage in
                guard let self = self, let errorMessage = errorMessage else { return }
                print("Speech recognition error: \(errorMessage)")
                // Optionally stop listening on errors
                if self.isListening {
                    self.stopListening()
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkPermissions() {
        // Request speech recognition authorization
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.audioPermissionStatus = status
                
                if status != .authorized {
                    print("Speech recognition permission not authorized: \(status.rawValue)")
                }
            }
        }
    }

    func setManualTranscript(_ text: String) {
        transcript = text
        objectWillChange.send()
    }

    func startListening() {
        guard !isListening else { return }
        
        print("VoiceBarViewModel: Starting to listen to system audio")
        transcript = "Listening..."
        
        // Start capturing system audio
        systemAudioCapture.startCapture { [weak self] buffer in
            // When a buffer is received, send it to the speech recognizer
            guard let self = self else { return }
            
            // If speech recognizer isn't transcribing yet, start it
            if !self.speechRecognizer.isTranscribing {
                self.speechRecognizer.startTranscribing(format: buffer.format)
            }
            
            // Process the audio buffer for transcription
            self.speechRecognizer.processAudioBuffer(buffer)
        }
        
        isListening = true
    }

    func stopListening() {
        guard isListening else { return }
        
        print("VoiceBarViewModel: Stopping system audio listening")
        
        // Stop system audio capture
        systemAudioCapture.stopCapture()
        
        // Stop speech recognition
        speechRecognizer.stopTranscribing()
        
        isListening = false
        
        // Reset the transcript after a delay if it's still just "Listening..."
        if transcript == "Listening..." {
            transcript = "Ready to transcribe"
        }
    }

    func toggleListening() {
        isListening ? stopListening() : startListening()
    }
    
    deinit {
        stopListening()
        cancellables.removeAll()
    }
}
