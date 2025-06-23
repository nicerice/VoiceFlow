//
//  TranscriptionService.swift
//  VoiceFlow
//
//  Created by Sebastian Reimann on 23.06.25.
//

import Foundation
import AVFoundation
import WhisperKit

@MainActor
class TranscriptionService: ObservableObject {
    private var whisperKit: WhisperKit?
    private var isInitialized = false
    
    @Published var modelLoadingProgress: Double = 0.0
    @Published var isModelLoading = false
    
    init() {
        Task {
            await initializeWhisperKit()
        }
    }
    
    // MARK: - Initialization
    
    private func initializeWhisperKit() async {
        print("TranscriptionService: Initializing WhisperKit...")
        isModelLoading = true
        modelLoadingProgress = 0.1
        
        do {
            // Initialize WhisperKit with explicit model configuration
            print("TranscriptionService: Creating WhisperKit instance with model...")
            modelLoadingProgress = 0.3
            
            // Try to initialize with a specific small model first
            whisperKit = try await WhisperKit(model: "base", modelRepo: "argmaxinc/whisperkit-coreml")
            
            modelLoadingProgress = 0.7
            print("TranscriptionService: WhisperKit instance created, finalizing setup...")
            
            // Allow some time for the model to fully load
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            
            isInitialized = true
            isModelLoading = false
            modelLoadingProgress = 1.0
            print("TranscriptionService: WhisperKit initialized successfully with base model")
        } catch {
            print("TranscriptionService: Failed to initialize WhisperKit: \(error)")
            print("TranscriptionService: Error details: \(error.localizedDescription)")
            isModelLoading = false
            isInitialized = false
            modelLoadingProgress = 0.0
            whisperKit = nil
        }
    }
    
    // MARK: - Transcription
    
    func transcribeAudio(from url: URL) async throws -> String {
        print("TranscriptionService: Starting transcription for file: \(url.lastPathComponent)")
        print("TranscriptionService: File path: \(url.path)")
        print("TranscriptionService: File size: \(getFileSize(url: url)) bytes")
        print("TranscriptionService: isInitialized = \(isInitialized), whisperKit = \(whisperKit != nil)")
        
        // Check if audio file exists and has content
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: url.path) else {
            print("TranscriptionService: Audio file does not exist")
            return "Audio file not found. Please try recording again."
        }
        
        let fileSize = getFileSize(url: url)
        if fileSize < 1000 { // Less than 1KB probably means no audio
            print("TranscriptionService: Audio file too small (\(fileSize) bytes), likely no audio recorded")
            return "Recording too short or empty. Please record for at least 1-2 seconds."
        }
        
        // If WhisperKit isn't ready, fall back to simulation for now
        guard isInitialized, let whisperKit = whisperKit else {
            print("TranscriptionService: WhisperKit not ready, using fallback simulation")
            return await simulateTranscription(for: url)
        }
        
        do {
            let transcriptionResults = try await whisperKit.transcribe(audioPath: url.path)
            let transcribedText = transcriptionResults.map { $0.text }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            
            print("TranscriptionService: Raw transcription results: \(transcriptionResults)")
            print("TranscriptionService: Combined text: '\(transcribedText)'")
            
            // Check if WhisperKit detected only music/noise or empty result
            if transcribedText.isEmpty || transcribedText.lowercased().contains("[music]") || transcribedText == "[Music]" {
                print("TranscriptionService: Detected music/noise or empty - possibly no clear speech")
                return "No clear speech detected. Please speak more clearly and try again."
            }
            
            print("TranscriptionService: Transcription completed: '\(transcribedText)'")
            return transcribedText
        } catch {
            print("TranscriptionService: Transcription failed with error: \(error)")
            print("TranscriptionService: Falling back to simulation")
            return await simulateTranscription(for: url)
        }
    }
    
    private func simulateTranscription(for url: URL) async -> String {
        // Simulate processing time
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Return a realistic fallback message
        return "Transcription simulation - WhisperKit model is still loading or encountered an error. Please try again in a moment."
    }
    
    
    // MARK: - Utility Methods
    
    private func getFileSize(url: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    func checkModelAvailability() -> Bool {
        return isInitialized
    }
    
    func resetService() async {
        isInitialized = false
        modelLoadingProgress = 0.0
        whisperKit = nil
        await initializeWhisperKit()
    }
}

// MARK: - Extended Error Types

extension VoiceFlowError {
    static let transcriptionServiceInitFailed = VoiceFlowError.transcriptionFailed
    static let transcriptionServiceNotReady = VoiceFlowError.transcriptionFailed
    static let modelLoadingFailed = VoiceFlowError.transcriptionFailed
    static let audioFileNotFound = VoiceFlowError.transcriptionFailed
    static let unsupportedAudioFormat = VoiceFlowError.transcriptionFailed
}