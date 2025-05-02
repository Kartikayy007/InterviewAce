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
        HStack {
            // Screenshot Button
            HStack(spacing: 8) {
                Text("Take screenshot")
                ShortcutKeyView(text: "⌘ ⇧ S")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)

            // Voice Status Button
//            HStack(spacing: 8) {
//                Text("Idle")
//                ShortcutKeyView(text:   "⌘ V")
//            }
//            .padding(.horizontal, 12)
//            .padding(.vertical, 6)
//            .background(Color.white.opacity(0.1))
//            .cornerRadius(10)
            

            // Stop Button
            HStack(spacing: 8) {
                Text("⏹ Stop")
                ShortcutKeyView(text: "⌘ S")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)
            
            HStack(spacing: 8) {
                // Include the toggle icon next to the text
                Image(systemName: minimizeVM.isMinimized ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 12))
                
                Text("Minimize")
                ShortcutKeyView(text: "⌘ ⇧ M")
                
            }
            .padding(.horizontal, 12)
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
                    .padding(6)
                    .clipShape(Circle())
            }
            .popover(isPresented: $showSettings, arrowEdge: .top) {
                SettingsTooltipView(isDarkMode: $isDarkMode)
            }
        }
        .padding(.horizontal, minimizeVM.isMinimized ? 4 : 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial) // nice glassy look
        .cornerRadius(16)
        .padding(.horizontal, minimizeVM.isMinimized ? 0 : 40)
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

struct SettingsTooltipView: View {
    @Binding var isDarkMode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)
                .padding(.bottom, 4)

            Divider()

            Toggle(isOn: $isDarkMode) {
                HStack {
                    Text("Dark Mode")
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
        .padding()
        .frame(width: 200)
        .background(Color.gray.opacity(0.5))
        .cornerRadius(12)
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
}
