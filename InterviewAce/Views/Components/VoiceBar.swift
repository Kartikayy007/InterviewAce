import SwiftUI

/// Voice input bar component shown in the left column
/// Uses the glass box design while maintaining visual appearance
struct VoiceBar: View {
    @StateObject var viewModel: VoiceBarViewModel
    @EnvironmentObject var aiViewModel: AIViewModel
    @State private var showTextInput = false
    @State private var textInput = ""
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHoveringMic = false
    @State private var isHoveringKeyboard = false
    @State private var animationValue: Double = 0

    var body: some View {
        ZStack {
            // Background
            glassBoxBackground
            
            // Content layout with smooth transitions between modes
            ZStack {
                // Voice input mode
                voiceInputView
                    .opacity(showTextInput ? 0 : 1)
                
                // Text input mode
                textInputView
                    .opacity(showTextInput ? 1 : 0)
            }
            .animation(.easeInOut(duration: 0.3), value: showTextInput)
        }
        .frame(width: 700, height: 80)
    }
    
    // MARK: - Background Views
    
    // The basic glass box background
    private var glassBoxBackground: some View {
        baseGlassBox
            .applyGlowEffect(isActive: aiViewModel.isProcessing)
    }
    
    // Base glass box without glow
    private var baseGlassBox: some View {
        RoundedRectangle(cornerRadius: 24)
            .stroke(
                colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.2),
                lineWidth: 2
            )
            .background(
                glassBoxFill
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(
                color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1),
                radius: 10, x: 0, y: 5
            )
    }
    
    // Simplified glass box fill
    private var glassBoxFill: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color.clear)
            .background(.ultraThinMaterial)
    }
    
    // MARK: - Voice Input View
    private var voiceInputView: some View {
        HStack(spacing: 15) {
            // Voice control button
            voiceControlSection
            
            Spacer()
            
            // Display transcript or thinking indicator
            transcriptOrThinkingSection
            
            // Keyboard toggle button
            keyboardToggleButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    // Voice control section with button and shortcut
    private var voiceControlSection: some View {
        HStack(spacing: 8) {
            voiceButton
            ShortcutKeyView(text: "⌘ ⇧ V")
        }
    }
    
    // Voice toggle button
    private var voiceButton: some View {
        Button(action: {
            viewModel.toggleListening()
        }) {
            voiceButtonContent
        }
        .buttonStyle(PlainButtonStyle())
        .help(viewModel.isListening ? "Stop listening" : "Start listening")
    }
    
    // Voice button visual content
    private var voiceButtonContent: some View {
        ZStack {
            if !viewModel.isListening {
                micIcon
            }
            
            if viewModel.isListening {
                recordingWaveformView
            }
        }
    }
    
    // Mic icon
    private var micIcon: some View {
        Image(systemName: "mic.fill")
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .font(.system(size: 18))
            .transition(.scale.combined(with: .opacity))
    }
    
    // Transcript or thinking section
    private var transcriptOrThinkingSection: some View {
        Group {
            if aiViewModel.isProcessing {
                thinkingIndicator
            } else {
                AnimatedTranscriptView(text: viewModel.transcript)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .font(.system(size: 18, weight: .medium))
            }
        }
    }
    
    // MARK: - Thinking Indicator
    private var thinkingIndicator: some View {
        HStack(spacing: 4) {
            Text("Thinking")
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .font(.system(size: 18, weight: .medium))
            
            thinkingDots
        }
    }
    
    // Animated thinking dots
    private var thinkingDots: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                thinkingDot(index: index)
            }
        }
        .onAppear {
            startThinkingDotsAnimation()
        }
    }
    
    // Individual thinking dot
    private func thinkingDot(index: Int) -> some View {
        Circle()
            .fill(colorScheme == .dark ? Color.white : Color.black)
            .frame(width: 4, height: 4)
            .opacity(0.7)
            .scaleEffect(animationValue == Double(index) ? 1.5 : 1)
    }
    
    // Start thinking dots animation
    private func startThinkingDotsAnimation() {
        withAnimation(Animation.easeInOut(duration: 0.6).repeatForever()) {
            animationValue = animationValue < 2 ? animationValue + 1 : 0
        }
    }
    
    // MARK: - Keyboard Toggle Button
    private var keyboardToggleButton: some View {
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
                switchToTextInput()
            }
            .help("Switch to keyboard input")
    }
    
    // Switch to text input mode
    private func switchToTextInput() {
        withAnimation(.easeInOut) {
            viewModel.stopListening()
            showTextInput = true
        }
    }
    
    // MARK: - Text Input View
    private var textInputView: some View {
        HStack(spacing: 8) {
            textField
            submitButton
            micToggleButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    // Text field
    private var textField: some View {
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
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button(action: submitTextInput) {
            Image(systemName: "arrow.up")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .padding(8)
        }
        .disabled(textInput.isEmpty)
        .buttonStyle(PlainButtonStyle())
        .opacity(textInput.isEmpty ? 0.5 : 1.0)
    }
    
    // MARK: - Mic Toggle Button
    private var micToggleButton: some View {
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
                switchToVoiceInput()
            }
    }
    
    // Switch to voice input mode
    private func switchToVoiceInput() {
        withAnimation(.easeInOut) {
            textInput = ""
            showTextInput = false
        }
    }

    // MARK: - Waveform View
    private var recordingWaveformView: some View {
        waveformBase
            .overlay {
                waveformOverlay
            }
    }
    
    // Waveform base
    private var waveformBase: some View {
        Image(systemName: "waveform")
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .font(.system(size: 22))
            .compositingGroup()
            .transition(.scale.combined(with: .opacity))
    }
    
    // Waveform overlay
    private var waveformOverlay: some View {
        ZStack {
            waveformDot
        }
        .phaseAnimator([0, 1]) { content, phase in
            content
                .scaleEffect(phase == 1 ? 1.5 : 1)
                .opacity(phase == 1 ? 1 : 0.7)
        } animation: { _ in Animation.bouncy(duration: 2.4).delay(0.6) }
    }
    
    // Waveform dot
    private var waveformDot: some View {
        Circle()
            .fill(colorScheme == .dark ? .white : .black)
            .frame(width: 6, height: 6)
            .opacity(0.5)
            .offset(y: 8)
    }

    // Submit text input
    private func submitTextInput() {
        guard !textInput.isEmpty else { return }

        // Set the transcript to the text input
        viewModel.setManualTranscript(textInput)

        // Clear the text input and switch back to voice mode
        textInput = ""
        showTextInput = false
    }
}

// MARK: - Helper Extension for Glow Effect
extension View {
    func applyGlowEffect(isActive: Bool) -> some View {
        let colors: [Color] = [.blue, .purple, .pink, .orange]
        let glowRadius: CGFloat = 6
        let glowOpacity: Double = 0.8
        let pulsateIntensity: Double = 0.03
        
        return self.modifier(SimpleGlowModifier(
            isActive: isActive,
            colors: colors,
            glowRadius: glowRadius,
            glowOpacity: glowOpacity,
            pulsateIntensity: pulsateIntensity
        ))
    }
}

// A simplified glow modifier that avoids complex animations
struct SimpleGlowModifier: ViewModifier {
    let isActive: Bool
    let colors: [Color]
    let glowRadius: CGFloat
    let glowOpacity: Double
    let pulsateIntensity: Double
    
    @State private var rotationValue: Double = 0
    @State private var scaleValue: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                glowOverlay
            )
            .animation(.easeInOut(duration: 0.7), value: isActive)
    }
    
    @ViewBuilder
    private var glowOverlay: some View {
        if isActive {
            ZStack {
                // Base glow layer
                primaryGlowLayer
                // Secondary glow layer
                secondaryGlowLayer
            }
            .onAppear {
                startAnimations()
            }
            .onChange(of: isActive) { newValue in
                if newValue {
                    resetAndRestartAnimations()
                }
            }
        }
    }
    
    private var primaryGlowLayer: some View {
        RoundedRectangle(cornerRadius: 24)
            .strokeBorder(
                AngularGradient(
                    gradient: Gradient(colors: colors),
                    center: .center,
                    startAngle: .degrees(rotationValue),
                    endAngle: .degrees(rotationValue + 360)
                ),
                lineWidth: 2
            )
            .blur(radius: glowRadius)
            .opacity(glowOpacity)
    }
    
    private var secondaryGlowLayer: some View {
        RoundedRectangle(cornerRadius: 24)
            .strokeBorder(
                AngularGradient(
                    gradient: Gradient(colors: colors),
                    center: .center,
                    startAngle: .degrees(-rotationValue),
                    endAngle: .degrees(-rotationValue + 360)
                ),
                lineWidth: 1.5
            )
            .blur(radius: glowRadius * 1.5)
            .opacity(glowOpacity * 0.7)
            .scaleEffect(scaleValue)
    }
    
    private func startAnimations() {
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            rotationValue = 360
        }
        
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            scaleValue = 1.0 + pulsateIntensity
        }
    }
    
    private func resetAndRestartAnimations() {
        rotationValue = 0
        scaleValue = 1.0
        
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            rotationValue = 360
        }
        
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            scaleValue = 1.0 + pulsateIntensity
        }
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
        .mask(transcriptMask)
        .onChange(of: text) { _, newValue in
            processTextChange(newValue)
        }
        .onAppear {
            initializeText()
        }
    }
    
    private var transcriptMask: some View {
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
    }
    
    private func processTextChange(_ newValue: String) {
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
    
    private func initializeText() {
        let words = text.components(separatedBy: " ")
        previousWords = Array(words.dropLast())
        newWord = words.last ?? ""
        showNewWord = true
    }
}
