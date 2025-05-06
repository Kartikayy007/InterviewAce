//
//  SecondaryBox.swift
//  InterviewAce
//
//  Created by kartikay on 01/05/25.
//


import SwiftUI

struct OutputCodeView: View {
    @EnvironmentObject var aiViewModel: AIViewModel
    // Use a computed property to always get the latest code from the selected card
    private var currentCode: String {
        return aiViewModel.selectedCodeCard?.code ?? ""
    }
    private var currentLanguage: String {
        return aiViewModel.selectedCodeCard?.language ?? "text"
    }

    // State variables for editing
    @State private var editableCode: String = ""
    @State private var isEditing: Bool = false
    @State private var debugMessage: String = "No code card selected yet"
    @State private var forceRefresh: UUID = UUID() // Use UUID for better refresh control

    // Initialize editableCode with the current code when the view is created
    init() {
        _editableCode = State(initialValue: "")

        // Log initialization
        print("OutputCodeView: Initialized")
    }

    // Add an onAppear action to set up notification observer
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("CodeCardSelected"),
            object: nil,
            queue: .main
        ) { notification in
            if let cardTitle = notification.userInfo?["cardTitle"] as? String,
               let codeLength = notification.userInfo?["codeLength"] as? Int {
                print("OutputCodeView: Received notification for card: \(cardTitle), code length: \(codeLength)")

                // Force a refresh on the main thread
                DispatchQueue.main.async {
                    // Force a refresh
                    self.forceRefresh = UUID()

                    // Update debug message
                    self.debugMessage = "Card from notification: \(cardTitle), length: \(codeLength)"
                }
            }
        }
    }

    var body: some View {
        // Check if we have a selected code card at the beginning of body evaluation
        let hasSelectedCard = aiViewModel.selectedCodeCard != nil
        let selectedCardTitle = aiViewModel.selectedCodeCard?.title ?? "None"

        // Log debug info outside the view hierarchy
        DispatchQueue.main.async {
            print("OutputCodeView body: hasSelectedCard=\(hasSelectedCard), title=\(selectedCardTitle), forceRefresh=\(self.forceRefresh)")
        }

        return ZStack {
            // Use the GlassBox component as the background
            GlassBox(title: "", height: 400)

            VStack(alignment: .leading, spacing: 12) {
                // Title area with controls
                HStack {
                    if let selectedCard = aiViewModel.selectedCodeCard {
                        Text(selectedCard.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        Spacer()

                        // Language badge
                        Text(selectedCard.language)
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.3))
                            .cornerRadius(4)
                            .foregroundColor(.white.opacity(0.9))

                        // Edit button
                        Button(action: {
                            isEditing.toggle()
                        }) {
                            Image(systemName: isEditing ? "checkmark" : "pencil")
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                                .padding(6)
                                .background(Circle().fill(Color.blue.opacity(0.3)))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help(isEditing ? "Save changes" : "Edit code")
                    } else {
                        Text("Code Editor")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        Spacer()
                    }
                }
                .padding(.bottom, 4)

                Divider()
                    .background(Color.white.opacity(0.3))

                // Code editor area
                if hasSelectedCard, let selectedCard = aiViewModel.selectedCodeCard {
                    VStack {
                        HStack {
                            Text("Selected card: \(selectedCard.title)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.green)

                            Spacer()

                            // Add a refresh button
                            Button(action: {
                                print("OutputCodeView: Manual refresh triggered")
                                // Force update the code text from the selected card
                                editableCode = selectedCard.code
                                // Toggle force refresh to trigger a view update
                                forceRefresh = UUID()
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.white)
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help("Refresh code view")
                        }
                        .padding(.bottom, 8)

                        // Add a debug label to show code length
                        Text("Code length: \(currentCode.count) chars")
                            .font(.system(size: 12))
                            .foregroundColor(.orange.opacity(0.8))
                            .padding(.bottom, 4)

                        // Use a direct approach to display the code
                        VStack {
                            // Debug info to show what's happening
                            HStack {
                                Text("Code length: \(currentCode.count) chars")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange.opacity(0.8))

                                Spacer()

                                // Add a refresh button
                                Button(action: {
                                    print("OutputCodeView: Manual refresh triggered")
                                    // Update the editable code
                                    editableCode = currentCode
                                    // Generate a new UUID to force refresh
                                    forceRefresh = UUID()
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundColor(.white)
                                        .font(.system(size: 12))
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help("Refresh code view")
                            }
                            .padding(.bottom, 4)

                            // Use a ZStack to show either a placeholder or the code
                            ZStack {
                                // Show a placeholder while code is empty
                                if currentCode.isEmpty {
                                    Text("No code available in the selected card")
                                        .foregroundColor(.white.opacity(0.6))
                                        .italic()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background(Color.black.opacity(0.3))
                                } else {
                                    VStack(spacing: 8) {
                                        // Show a simple text view with the code for debugging
                                        ScrollView {
                                            Text(currentCode)
                                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                                .foregroundColor(.white.opacity(0.9))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(8)
                                        }
                                        .frame(height: 100) // Limit height to make room for the code editor
                                        .background(Color.black.opacity(0.3))
                                        .cornerRadius(8)

                                        Divider()
                                            .background(Color.white.opacity(0.3))
                                            .padding(.vertical, 4)

                                        Text("Code Editor View:")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white.opacity(0.8))
                                            .frame(maxWidth: .infinity, alignment: .leading)

                                        // The actual code editor
                                        CodeEditorView(
                                            code: isEditing ? $editableCode : .constant(currentCode),
                                            language: currentLanguage,
                                            isEditable: isEditing
                                        )
                                        .frame(maxHeight: .infinity)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .id("code-display-\(forceRefresh)")
                    }
                } else {
                    // No code selected
                    VStack(spacing: 16) {
                        Spacer()
                        Text("Select a code card to view code")
                            .foregroundColor(.white.opacity(0.6))
                            .italic()

                        // Debug info
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Debug: \(debugMessage)")
                                .font(.system(size: 12))
                                .foregroundColor(.red.opacity(0.8))

                            Text("Has card at render: \(hasSelectedCard ? "Yes" : "No")")
                                .font(.system(size: 12))
                                .foregroundColor(.orange.opacity(0.8))

                            Text("Card title at render: \(selectedCardTitle)")
                                .font(.system(size: 12))
                                .foregroundColor(.green.opacity(0.8))
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(4)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(20)
            .onReceive(aiViewModel.$selectedCodeCard) { newCard in
                print("OutputCodeView: Received new selected code card: \(String(describing: newCard?.title))")

                if let card = newCard {
                    debugMessage = "Card received: \(card.title), code length: \(card.code.count)"

                    // Update the editable code for when editing is enabled
                    editableCode = card.code
                    isEditing = false

                    // Force a refresh by generating a new UUID
                    forceRefresh = UUID()

                    // Log the code content for debugging
                    print("OutputCodeView: Code content: \(card.code.prefix(100))...")
                    print("OutputCodeView: Card code length: \(card.code.count) chars")
                    print("OutputCodeView: Current code computed property: \(currentCode.count) chars")

                    // Force UI update after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // This is just to trigger a UI update
                        self.debugMessage += " (processed)"
                        // Force another refresh
                        self.forceRefresh = UUID()
                    }
                } else {
                    debugMessage = "Received nil card"
                }
            }
            .onAppear {
                // Set up the notification observer
                setupNotificationObserver()

                // Check if there's already a selected code card when the view appears
                if let selectedCard = aiViewModel.selectedCodeCard {
                    print("OutputCodeView: View appeared with selected card: \(selectedCard.title)")
                    debugMessage = "Card present on appear: \(selectedCard.title)"

                    // Update the editable code
                    editableCode = selectedCard.code

                    // Force a refresh
                    forceRefresh = UUID()

                    print("OutputCodeView: Current code on appear: \(currentCode.count) chars")

                    // Print the actual code content for debugging
                    print("OutputCodeView: Code content on appear: \(selectedCard.code.prefix(100))...")
                } else {
                    print("OutputCodeView: View appeared with no selected card")
                }

                // Force another refresh after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    print("OutputCodeView: Forcing refresh after delay")
                    self.forceRefresh = UUID()
                }
            }
        }
    }
}

// Preview provider to see this component in isolation
#Preview {
    OutputCodeView()
        .environmentObject(AIViewModel())
        .frame(width: 500, height: 400)
        .background(Color.black)
}
