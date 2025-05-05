import SwiftUI

/// Voice input bar component shown in the left column
/// Uses the glass box design while maintaining visual appearance
struct VoiceBar: View {
    @StateObject var viewModel: VoiceBarViewModel
    @State private var showTextInput = false
    @State private var textInput = ""
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHoveringMic = false
    @State private var isHoveringKeyboard = false
    
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
            
            // Content layout with smooth transitions between modes
            ZStack {
                // Voice input mode
                HStack(spacing: 15) {
                    HStack(spacing: 8) {
                        // Toggle button with animation - no background
                        Button(action: {
                            viewModel.toggleListening()
                        }) {
                            ZStack {
                                if !viewModel.isListening {
                                    Image(systemName: "mic.fill")
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        .font(.system(size: 18))
                                        .transition(
                                            .asymmetric(
                                                insertion: .modifier(active: RecordingIconTransitionModifier(isIdentity: false), identity: RecordingIconTransitionModifier(isIdentity: true)).animation(.bouncy(extraBounce: 0.3).delay(0.2)),
                                                removal: .modifier(active: RecordingIconTransitionModifier(isIdentity: false), identity: RecordingIconTransitionModifier(isIdentity: true)).animation(.bouncy(extraBounce: 0.3))
                                            )
                                        )
                                }

                                if viewModel.isListening {
                                    recordingWaveformView
                                        .transition(
                                            .asymmetric(
                                                insertion: .scale.combined(with: .opacity).animation(.bouncy(extraBounce: 0.3).delay(0.2)),
                                                removal: .scale.combined(with: .opacity).animation(.bouncy)
                                            )
                                        )
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help(viewModel.isListening ? "Stop listening" : "Start listening")
                        
                        ShortcutKeyView(text: "⌘ ⇧ V")
                    }

                    Spacer()

                    // Display transcript text (just visual)
                    AnimatedTranscriptView(text: viewModel.transcript)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .font(.system(size: 18, weight: .medium))
                    
                    // Text/voice toggle with hover effect
                    Image(systemName: "keyboard")
                        .font(.system(size: 18))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .opacity(isHoveringKeyboard ? 1.0 : 0.7)
                        .scaleEffect(isHoveringKeyboard ? 1.1 : 1.0)
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isHoveringKeyboard = hovering
                            }
                        }
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                viewModel.stopListening()
                                showTextInput = true
                            }
                        }
                        .help("Switch to keyboard input")
                }
                .opacity(showTextInput ? 0 : 1)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                // Text input mode
                HStack(spacing: 8) {
                    TextField("Type your question...", text: $textInput)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(10)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .submitLabel(.send)
                        .onSubmit {
                            submitTextInput()
                        }
                    
                    Button(action: submitTextInput) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding(8)
                    }
                    .disabled(textInput.isEmpty)
                    .buttonStyle(PlainButtonStyle())
                    .opacity(textInput.isEmpty ? 0.5 : 1.0)
                    
                    Image(systemName: "mic")
                        .font(.system(size: 18))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .opacity(isHoveringMic ? 1.0 : 0.7)
                        .scaleEffect(isHoveringMic ? 1.1 : 1.0)
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isHoveringMic = hovering
                            }
                        }
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                textInput = ""
                                showTextInput = false
                            }
                        }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .opacity(showTextInput ? 1 : 0)
            }
            .animation(.easeInOut(duration: 0.3), value: showTextInput)
        }
        .frame(height: 80)
    }
    
    @ViewBuilder
    private var recordingWaveformView: some View {
        Image(systemName: "waveform")
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .font(.system(size: 22))
            .compositingGroup()
            .overlay {
                ZStack {
                    Circle()
                        .fill(colorScheme == .dark ? .white : .black)
                        .frame(width: 6, height: 6)
                        .opacity(0.5)
                        .offset(y: 8)
                }
                .phaseAnimator([0, 1]) { content, phase in
                    content
                        .scaleEffect(phase == 1 ? 1.5 : 1)
                        .opacity(phase == 1 ? 1 : 0.7)
                } animation: { _ in Animation.bouncy(duration: 2.4).delay(0.6) }
            }
    }
    
    private func submitTextInput() {
        guard !textInput.isEmpty else { return }
        
        // Set the transcript to the text input
        viewModel.setManualTranscript(textInput)
        
        // Clear the text input and switch back to voice mode
        textInput = ""
        showTextInput = false
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
                    .init(color: .black, location: 0.5),
                    .init(color: .black, location: 0.75),
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

#Preview {
    VoiceBar(viewModel: VoiceBarViewModel())
        .environmentObject(MinimizeViewModel())
        .environmentObject(VoiceBarViewModel())
        .environmentObject(AIViewModel())
}
