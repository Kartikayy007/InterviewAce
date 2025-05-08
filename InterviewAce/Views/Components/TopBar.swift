//
//  Topbor.swift
//  InterviewAce
//
//  Created by kartikay on 01/05/25.
//

import SwiftUI

struct TopBar: View {
    @State private var showSettings = false
    @AppStorage("isDarkMode") private var isDarkMode = true
    @EnvironmentObject var minimizeVM: MinimizeViewModel

    var body: some View {
        HStack(spacing: minimizeVM.isMinimized ? 8 : 12) { // Adjust spacing based on mode
            // Screenshot Button
            HStack(spacing: 8) {
                Text("Take Screenshot")
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false) // Prevent text wrapping
                ShortcutKeyView(text: "⌘ ⇧ S")
            }
            .padding(.horizontal, minimizeVM.isMinimized ? 8 : 12) // Smaller padding when minimized
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)

            // Stop Button
            HStack(spacing: 8) {
                Text("⏹ Stop")
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false) // Prevent text wrapping
                ShortcutKeyView(text: "⌘ S")
            }
            .padding(.horizontal, minimizeVM.isMinimized ? 8 : 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)

//            HStack(spacing: 8) {
//                Text("↻ Restart")
//                    .lineLimit(1)
//                    .fixedSize(horizontal: true, vertical: false) // Prevent text wrapping
//                ShortcutKeyView(text: "⌘ S")
//            }
//            .padding(.horizontal, minimizeVM.isMinimized ? 8 : 12)
//            .padding(.vertical, 6)
//            .background(Color.white.opacity(0.1))
//            .cornerRadius(10)

            // Minimize Button
            HStack(spacing: 8) {
                Image(systemName: minimizeVM.isMinimized ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 12))

                Text(minimizeVM.isMinimized ? "Expand" : "Minimize")
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false) // Prevent text wrapping

                ShortcutKeyView(text: "⌘ ⇧ M")
            }
            .padding(.horizontal, minimizeVM.isMinimized ? 8 : 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)
            .onTapGesture {
                minimizeVM.toggle()
            }

            // Settings Gear with Tooltip
            Button(action: {
                showSettings.toggle()
            }) {
                Image(systemName: "gear")
                    .padding(minimizeVM.isMinimized ? 4 : 6)
                    .clipShape(Circle())
            }
            .popover(isPresented: $showSettings, arrowEdge: .top) {
                SettingsTooltipView(isDarkMode: $isDarkMode)
            }
        }
        .padding(.horizontal, minimizeVM.isMinimized ? 8 : 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding(.horizontal, 0)
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

struct SettingsTooltipView: View {
    @Binding var isDarkMode: Bool
    @State private var showAboutInfo: Bool = false
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("useSmartModel") private var useSmartModel: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Settings")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .padding(.bottom, 4)

            Divider()

            // Dark Mode Toggle with improved layout
            HStack {
                Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                    .foregroundColor(isDarkMode ? .yellow : .orange)
                    .font(.system(size: 16))
                    .frame(width: 24)

                Text("Dark Mode")
                    .font(.subheadline)

                Spacer()

                Toggle("", isOn: $isDarkMode)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .labelsHidden()
            }
            .padding(.vertical, 2)

            // AI Model Toggle
            HStack {
                Image(systemName: useSmartModel ? "brain" : "bolt.fill")
                    .foregroundColor(useSmartModel ? .purple : .orange)
                    .font(.system(size: 16))
                    .frame(width: 24)

                Text(useSmartModel ? "Smart" : "Fast")
                    .font(.subheadline)

                Spacer()

                Toggle("", isOn: $useSmartModel)
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                    .labelsHidden()
                    .onChange(of: useSmartModel) { newValue in
                        let modelName = newValue ? "Smart (Gemini 2.0 Flash)" : "Fast (Gemini 2.0 Flash-Lite)"
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ModelChanged"),
                            object: nil,
                            userInfo: ["modelName": modelName]
                        )
                    }
            }
            .padding(.vertical, 2)

            Divider()

            // Menu Buttons with consistent styling
            MenuButton(icon: "info.circle", iconColor: .blue, text: "About") {
                showAboutInfo.toggle()
            }
            .popover(isPresented: $showAboutInfo, arrowEdge: .leading) {
                AboutView()
            }

            MenuButton(icon: "arrow.right.square", iconColor: .orange, text: "Logout") {
                logout()
            }

            MenuButton(icon: "power", iconColor: .red, text: "Quit") {
                quitApp()
            }
        }
        .padding()
        .frame(width: 240)
        .background(colorScheme == .dark ? Color(hex: "1E1E1E") : Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }

    // Function to quit the application
    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // Function to restart the application
    private func restartApp() {
        let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [path]
        task.launch()
        NSApplication.shared.terminate(nil)
    }

    // Function to logout (you would implement your actual logout logic here)
    private func logout() {
        // Implement your logout logic here
        // This could involve clearing user data, tokens, etc.
        print("User logged out")
    }
}

// A reusable button component for the menu items
struct MenuButton: View {
    var icon: String
    var iconColor: Color
    var text: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 14))
                    .frame(width: 24)

                Text(text)
                    .font(.subheadline)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.gray.opacity(0.7))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(MenuButtonStyle())
    }
}

struct MenuButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(
                configuration.isPressed ?
                (colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)) :
                Color.clear
            )
            .cornerRadius(8)
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// About view to show app information
struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("InterviewAce")
                .font(.headline)
                .bold()

            Text("Version 1.0")
                .font(.subheadline)

            Divider()

            Text("A floating overlay app to help with interview preparation.")
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            Text("© 2025 InterviewAce")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding()
        .frame(width: 250)
    }
}

struct ShortcutKeyView: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.white.opacity(0.2))
            .cornerRadius(6)
    }
}

#Preview {
    TopBar()
        .environmentObject(MinimizeViewModel())
}
