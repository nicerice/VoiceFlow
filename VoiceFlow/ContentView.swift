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
    @State private var isRecording = false
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("VOICE FLOW")
                .font(.system(size: 28, weight: .bold, design: .default))
                .tracking(2)
                .padding(.top, 10)
            
            // Main content area
            TextDisplayView(
                text: $transcribedText,
                isLoading: $isLoading
            )
            .frame(maxHeight: .infinity)
            
            // Button row
            HStack(spacing: 30) {
                CopyButton(
                    action: {
                        copyToClipboard()
                    },
                    isEnabled: !transcribedText.isEmpty && !isLoading
                )
                
                RecordButton(
                    isRecording: $isRecording,
                    action: {
                        toggleRecording()
                    }
                )
                .disabled(isLoading)
                
                MagicWandButton(
                    action: {
                        processMagicWand()
                    },
                    isEnabled: !transcribedText.isEmpty && !isLoading
                )
            }
            .padding(.bottom, 10)
            
            // Test buttons (development only)
            #if DEBUG
            HStack {
                Button("Add Sample Text") {
                    transcribedText = "This is a sample transcription text for testing purposes. It demonstrates how the text display looks with actual content."
                }
                .font(.caption)
                
                Button("Clear Text") {
                    transcribedText = ""
                }
                .font(.caption)
                
                Button("Toggle Loading") {
                    isLoading.toggle()
                }
                .font(.caption)
            }
            .padding(.bottom, 5)
            #endif
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
    
    // MARK: - Actions
    
    private func copyToClipboard() {
        print("Copy tapped")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(transcribedText, forType: .string)
        
        // Visual feedback
        withAnimation(.easeInOut(duration: 0.2)) {
            // Could add a visual indicator here
        }
    }
    
    private func toggleRecording() {
        print("Record button tapped")
        isRecording.toggle()
        
        if isRecording {
            print("Recording started")
            // Start recording logic will go here
        } else {
            print("Recording stopped")
            // Stop recording logic will go here
        }
    }
    
    private func processMagicWand() {
        print("Magic wand tapped")
        isLoading = true
        
        // Simulate processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
            print("Magic wand processing complete")
        }
    }
}

#Preview {
    ContentView()
}
