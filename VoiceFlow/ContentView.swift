//
//  ContentView.swift
//  VoiceFlow
//
//  Created by Sebastian Reimann on 23.06.25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var transcribedText = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("VOICE FLOW")
                .font(.system(size: 28, weight: .bold, design: .default))
                .tracking(2)
                .padding(.top, 10)
            
            // Main content area
            VStack(alignment: .leading, spacing: 8) {
                Text("YOUR PROMPT")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .tracking(0.5)
                
                // Text display area
                ScrollView {
                    Text(transcribedText.isEmpty ? "Tap the record button to get started" : transcribedText)
                        .font(.system(size: 14))
                        .foregroundColor(transcribedText.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
                .frame(maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
            .frame(maxHeight: .infinity)
            
            // Button row
            HStack(spacing: 30) {
                // Copy button
                Button(action: {}) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
                .disabled(transcribedText.isEmpty)
                .opacity(transcribedText.isEmpty ? 0.5 : 1.0)
                
                // Record button
                Button(action: {}) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                
                // Magic wand button
                Button(action: {}) {
                    Image(systemName: "wand.and.rays")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
                .disabled(transcribedText.isEmpty)
                .opacity(transcribedText.isEmpty ? 0.5 : 1.0)
            }
            .padding(.bottom, 10)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
}

#Preview {
    ContentView()
}
