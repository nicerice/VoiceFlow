//
//  ContentView.swift
//  VoiceFlow
//
//  Created by Sebastian Reimann on 23.06.25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = RecordingViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("VOICE FLOW")
                .font(.system(size: 28, weight: .bold, design: .default))
                .tracking(2)
                .padding(.top, 10)
            
            // Main content area
            TextDisplayView(
                text: .constant(viewModel.currentText),
                isLoading: .constant(viewModel.isLoading),
                placeholderText: viewModel.placeholderText,
                loadingMessage: viewModel.loadingMessage
            )
            .frame(maxHeight: .infinity)
            
            // Button row
            HStack(spacing: 30) {
                CopyButton(
                    action: {
                        copyToClipboard()
                    },
                    isEnabled: !viewModel.currentText.isEmpty && !viewModel.isLoading
                )
                
                RecordButton(
                    isRecording: .constant(viewModel.isRecording),
                    action: {
                        toggleRecording()
                    }
                )
                .disabled(!viewModel.canRecord)
                
                MagicWandButton(
                    action: {
                        viewModel.startLLMProcessing()
                    },
                    isEnabled: viewModel.canProcessLLM,
                    isProcessing: viewModel.currentState == .processingLLM
                )
            }
            .padding(.bottom, 10)
            
            // Debug state display
            #if DEBUG
            VStack(spacing: 5) {
                Text("Current State: \(viewModel.currentState.description)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Button("Sample Text") {
                        viewModel.completeTranscription(text: "This is a sample transcription for testing.")
                    }
                    .font(.caption)
                    
                    Button("Reset") {
                        viewModel.reset()
                    }
                    .font(.caption)
                    
                    Button("Force Transcribe") {
                        viewModel.startTranscription()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            viewModel.completeTranscription(text: "Force transcribed text")
                        }
                    }
                    .font(.caption)
                }
            }
            .padding(.bottom, 5)
            #endif
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme == .dark ? Color.black : Color.white)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.showError = false
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An unknown error occurred")
        }
    }
    
    // MARK: - Actions
    
    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(viewModel.currentText, forType: .string)
    }
    
    private func toggleRecording() {
        if viewModel.isRecording {
            viewModel.stopRecording()
        } else {
            viewModel.startRecording()
        }
    }
}

#Preview {
    ContentView()
}
