//
//  RecordingViewModel.swift
//  VoiceFlow
//
//  Created by Sebastian Reimann on 23.06.25.
//

import Foundation
import SwiftUI
import AVFoundation

@MainActor
class RecordingViewModel: ObservableObject {
    @Published var currentState: AppState = .idle
    @Published var transcribedText: String = ""
    @Published var processedText: String = ""
    @Published var error: Error?
    @Published var showError: Bool = false
    
    private let audioRecorder = AudioRecorder()
    private let transcriptionService = TranscriptionService()
    private var currentRecordingURL: URL?
    
    // MARK: - Computed Properties for UI Binding
    
    var isRecording: Bool {
        return currentState.isRecording
    }
    
    var canRecord: Bool {
        return currentState.canRecord
    }
    
    var canProcessLLM: Bool {
        return currentState.canProcessLLM && !currentText.isEmpty
    }
    
    var isLoading: Bool {
        return currentState.isLoading
    }
    
    var currentText: String {
        switch currentState {
        case .idle:
            return ""
        case .recording:
            return transcribedText
        case .transcribing:
            return transcribedText
        case .transcribed:
            return transcribedText
        case .processingLLM:
            return processedText.isEmpty ? transcribedText : processedText
        case .processed:
            return processedText
        }
    }
    
    var recordButtonColor: Color {
        switch currentState {
        case .recording:
            return .red
        case .idle, .transcribed, .processed:
            return .red
        case .transcribing, .processingLLM:
            return .gray
        }
    }
    
    var placeholderText: String {
        switch currentState {
        case .idle:
            return "Tap the record button to get started"
        case .recording:
            return "Recording... Tap stop when finished"
        case .transcribing:
            return "Transcribing audio..."
        case .transcribed:
            return "Transcription complete"
        case .processingLLM:
            return "Processing with AI..."
        case .processed:
            return "Processing complete"
        }
    }
    
    var loadingMessage: String {
        switch currentState {
        case .transcribing:
            return "Transcribing audio..."
        case .processingLLM:
            return "Processing with AI..."
        default:
            return "Loading..."
        }
    }
    
    // MARK: - State Transition Methods
    
    func startRecording() {
        guard canRecord else { return }
        print("ViewModel: Starting recording")
        
        Task {
            do {
                let url = try await audioRecorder.startRecording()
                currentRecordingURL = url
                currentState = .recording
                transcribedText = ""
                processedText = ""
                error = nil
            } catch {
                handleError(error)
                if error is VoiceFlowError {
                    switch error as! VoiceFlowError {
                    case .permissionDenied:
                        NotificationHelper.shared.showPermissionDeniedNotification()
                    case .recordingSetupFailed, .recordingStartFailed:
                        NotificationHelper.shared.showRecordingErrorNotification()
                    default:
                        break
                    }
                }
            }
        }
    }
    
    func stopRecording() {
        guard currentState == .recording else { return }
        print("ViewModel: Stopping recording")
        
        if let recordingURL = audioRecorder.stopRecording() {
            currentRecordingURL = recordingURL
            currentState = .transcribing
            
            // Start actual transcription
            Task {
                do {
                    let transcribedText = try await transcriptionService.transcribeAudio(from: recordingURL)
                    completeTranscription(text: transcribedText)
                } catch {
                    handleError(error)
                    NotificationHelper.shared.showTranscriptionErrorNotification()
                }
            }
        } else {
            handleError(VoiceFlowError.recordingSetupFailed)
        }
    }
    
    func startTranscription() {
        print("ViewModel: Starting transcription")
        currentState = .transcribing
    }
    
    func completeTranscription(text: String) {
        print("ViewModel: Transcription completed")
        transcribedText = text
        currentState = .transcribed
    }
    
    func startLLMProcessing() {
        guard canProcessLLM else { return }
        print("ViewModel: Starting LLM processing")
        currentState = .processingLLM
        
        // Simulate LLM processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            let enhanced = "Enhanced: \(self.currentText)\n\nThis text has been processed and enhanced by AI to provide better clarity and structure."
            self.completeLLMProcessing(text: enhanced)
        }
    }
    
    func completeLLMProcessing(text: String) {
        print("ViewModel: LLM processing completed")
        processedText = text
        currentState = .processed
    }
    
    func reset() {
        print("ViewModel: Resetting to idle state")
        currentState = .idle
        transcribedText = ""
        processedText = ""
        error = nil
        showError = false
    }
    
    func handleError(_ error: Error) {
        print("ViewModel: Error occurred - \(error.localizedDescription)")
        self.error = error
        self.showError = true
        // Reset to previous stable state
        if currentState == .recording {
            currentState = .idle
        } else if currentState == .transcribing {
            currentState = .recording
        } else if currentState == .processingLLM {
            currentState = .transcribed
        }
    }
}