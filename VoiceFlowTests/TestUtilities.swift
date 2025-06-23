//
//  TestUtilities.swift
//  VoiceFlowTests
//
//  Created by Sebastian Reimann on 23.06.25.
//

import Foundation
import XCTest
@testable import VoiceFlow

/// Test utilities and mock data for comprehensive VoiceFlow testing
class TestUtilities {
    
    // MARK: - Mock Data Generation
    
    /// Generates realistic transcription text samples
    static func generateMockTranscriptions() -> [String] {
        return [
            "Hello, this is a test of the voice transcription system. It should accurately capture spoken words and convert them to text.",
            "The quick brown fox jumps over the lazy dog. This pangram contains all letters of the alphabet.",
            "Today's weather is partly cloudy with a chance of rain in the afternoon. Temperature will reach about 72 degrees.",
            "Please remember to call the doctor's office to schedule your annual checkup appointment for next month.",
            "I need to buy groceries including milk, bread, eggs, and fresh vegetables for this week's meal planning.",
            "The meeting is scheduled for 3 PM tomorrow in the conference room on the second floor of the building.",
            "Can you help me find the best route to downtown considering the current traffic conditions?",
            "The software update includes several bug fixes and new features that will improve user experience.",
            "I'm working on a presentation about artificial intelligence and machine learning applications in healthcare.",
            "Let's discuss the quarterly sales report and identify opportunities for growth in the next quarter."
        ]
    }
    
    /// Generates short transcription samples for testing edge cases
    static func generateShortTranscriptions() -> [String] {
        return [
            "Yes.",
            "No.",
            "Hello.",
            "Thanks.",
            "Goodbye.",
            "Maybe.",
            "Sure thing.",
            "I understand.",
            "Not really.",
            "Absolutely."
        ]
    }
    
    /// Generates long transcription samples for stress testing
    static func generateLongTranscriptions() -> [String] {
        return [
            """
            This is an extended transcription that simulates a lengthy voice recording session. 
            In real-world usage, users might dictate long emails, documents, or notes that contain 
            multiple sentences, paragraphs, and complex thoughts. The transcription service needs 
            to handle these longer inputs efficiently while maintaining accuracy and performance. 
            This sample text includes various punctuation marks, capitalization patterns, and 
            sentence structures that are common in natural speech patterns.
            """,
            """
            Today I want to discuss the importance of comprehensive testing in software development. 
            When building applications, especially those that involve complex user interactions like 
            voice recording and transcription, it's crucial to test not only the happy path scenarios 
            but also edge cases, error conditions, and performance under load. This includes testing 
            with various input types, different user behaviors, and potential system limitations. 
            A robust testing strategy helps ensure that the application performs reliably in real-world 
            conditions and provides a smooth user experience.
            """
        ]
    }
    
    /// Generates error-prone transcription scenarios
    static func generateErrorTranscriptions() -> [String] {
        return [
            "[Music]", // WhisperKit music detection
            "", // Empty transcription
            "   ", // Whitespace only
            "[Noise]", // Background noise detection
            "Uh, um, well, you know, like...", // Filler words
            "Testing... testing... one, two, three.", // Test audio
            "Can you hear me? Hello? Hello?", // Connection issues
            "This is very quiet whisper text.", // Low volume
            "SHOUTING VERY LOUD TRANSCRIPTION!", // High volume
            "Multiple... long... pauses... between... words." // Fragmented speech
        ]
    }
    
    // MARK: - Mock File Generation
    
    /// Creates a temporary audio file with specified properties
    static func createMockAudioFile(
        size: Int = 5000,
        name: String? = nil,
        extension: String = "wav"
    ) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = name ?? "mock_audio_\(UUID().uuidString)"
        let fileURL = tempDir.appendingPathComponent("\(fileName).\(`extension`)")
        
        // Create mock audio data
        let audioData = generateMockAudioData(size: size)
        try! audioData.write(to: fileURL)
        
        return fileURL
    }
    
    /// Generates mock audio data for testing
    private static func generateMockAudioData(size: Int) -> Data {
        // Create realistic audio file header for WAV format
        var data = Data()
        
        // WAV header (44 bytes)
        data.append("RIFF".data(using: .ascii)!) // ChunkID
        data.append(contentsOf: withUnsafeBytes(of: UInt32(size + 36).littleEndian) { Data($0) }) // ChunkSize
        data.append("WAVE".data(using: .ascii)!) // Format
        data.append("fmt ".data(using: .ascii)!) // Subchunk1ID
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) }) // Subchunk1Size
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) }) // AudioFormat
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) }) // NumChannels
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16000).littleEndian) { Data($0) }) // SampleRate
        data.append(contentsOf: withUnsafeBytes(of: UInt32(32000).littleEndian) { Data($0) }) // ByteRate
        data.append(contentsOf: withUnsafeBytes(of: UInt16(2).littleEndian) { Data($0) }) // BlockAlign
        data.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian) { Data($0) }) // BitsPerSample
        data.append("data".data(using: .ascii)!) // Subchunk2ID
        data.append(contentsOf: withUnsafeBytes(of: UInt32(size).littleEndian) { Data($0) }) // Subchunk2Size
        
        // Add mock audio data (sine wave pattern for realistic size)
        let audioContent = (0..<size).map { i in
            UInt8((sin(Double(i) * 0.1) * 127 + 128))
        }
        data.append(contentsOf: audioContent)
        
        return data
    }
    
    /// Creates multiple mock audio files for batch testing
    static func createMockAudioFiles(count: Int, sizes: [Int]? = nil) -> [URL] {
        let fileSizes = sizes ?? Array(repeating: 5000, count: count)
        return (0..<count).map { i in
            let size = i < fileSizes.count ? fileSizes[i] : 5000
            return createMockAudioFile(size: size, name: "batch_test_\(i)")
        }
    }
    
    // MARK: - Test State Helpers
    
    /// Creates a ViewModel in a specific state for testing
    @MainActor
    static func createViewModelInState(_ state: AppState, withText text: String = "") -> RecordingViewModel {
        let viewModel = RecordingViewModel()
        
        switch state {
        case .idle:
            break // Already in idle state
        case .recording:
            viewModel.currentState = .recording
        case .transcribing:
            viewModel.currentState = .transcribing
        case .transcribed:
            viewModel.completeTranscription(text: text.isEmpty ? "Mock transcribed text" : text)
        case .processingLLM:
            viewModel.completeTranscription(text: text.isEmpty ? "Mock text for LLM" : text)
            viewModel.currentState = .processingLLM
        case .processed:
            viewModel.completeTranscription(text: text.isEmpty ? "Original text" : text)
            viewModel.completeLLMProcessing(text: "Enhanced: \(text.isEmpty ? "Mock processed text" : text)")
        }
        
        return viewModel
    }
    
    /// Simulates a complete recording workflow
    @MainActor
    static func simulateRecordingWorkflow(
        viewModel: RecordingViewModel,
        transcriptionText: String = "Simulated transcription result"
    ) async {
        // Start recording
        viewModel.currentState = .recording
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Stop and transcribe
        viewModel.currentState = .transcribing
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
        
        viewModel.completeTranscription(text: transcriptionText)
    }
    
    // MARK: - Performance Measurement Helpers
    
    /// Measures execution time of a block
    static func measureTime<T>(_ block: () throws -> T) rethrows -> (result: T, time: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        return (result, timeElapsed)
    }
    
    /// Measures async execution time
    static func measureAsyncTime<T>(_ block: () async throws -> T) async rethrows -> (result: T, time: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        return (result, timeElapsed)
    }
    
    // MARK: - Error Simulation
    
    /// Simulates various error conditions for testing
    static func simulateErrors() -> [Error] {
        return [
            VoiceFlowError.permissionDenied,
            VoiceFlowError.recordingSetupFailed,
            VoiceFlowError.recordingStartFailed,
            VoiceFlowError.transcriptionFailed,
            VoiceFlowError.llmProcessingFailed,
            NSError(domain: "TestError", code: 999, userInfo: [NSLocalizedDescriptionKey: "Simulated network error"]),
            NSError(domain: "TestError", code: 404, userInfo: [NSLocalizedDescriptionKey: "File not found"]),
            NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        ]
    }
    
    // MARK: - Cleanup Helpers
    
    /// Cleans up temporary test files
    static func cleanupTestFiles(_ urls: [URL]) {
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    /// Cleans up all temporary test files matching pattern
    static func cleanupAllTestFiles() {
        let tempDir = FileManager.default.temporaryDirectory
        
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: tempDir,
                includingPropertiesForKeys: nil
            )
            
            let testFiles = files.filter { url in
                let name = url.lastPathComponent
                return name.contains("mock_") || 
                       name.contains("test_") || 
                       name.contains("perf_test_") ||
                       name.contains("batch_test_")
            }
            
            for file in testFiles {
                try? FileManager.default.removeItem(at: file)
            }
        } catch {
            print("Warning: Could not clean up test files: \(error)")
        }
    }
    
    // MARK: - Validation Helpers
    
    /// Validates that a URL points to a valid audio file
    static func validateAudioFile(_ url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else { return false }
        guard url.pathExtension.lowercased() == "wav" else { return false }
        
        do {
            let data = try Data(contentsOf: url)
            guard data.count > 44 else { return false } // Minimum WAV header size
            
            // Check WAV header
            let header = data.prefix(4)
            return header == "RIFF".data(using: .ascii)
        } catch {
            return false
        }
    }
    
    /// Validates transcription text quality
    static func validateTranscriptionQuality(_ text: String) -> (isValid: Bool, issues: [String]) {
        var issues: [String] = []
        
        if text.isEmpty {
            issues.append("Empty transcription")
        }
        
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append("Whitespace-only transcription")
        }
        
        if text == "[Music]" || text == "[Noise]" {
            issues.append("Non-speech detection")
        }
        
        if text.count < 3 {
            issues.append("Transcription too short")
        }
        
        if text.count > 10000 {
            issues.append("Transcription extremely long")
        }
        
        let suspiciousPatterns = ["test", "testing", "check", "one two three"]
        for pattern in suspiciousPatterns {
            if text.lowercased().contains(pattern) {
                issues.append("Contains test pattern: \(pattern)")
            }
        }
        
        return (issues.isEmpty, issues)
    }
}

// MARK: - Test Extensions

extension XCTestCase {
    /// Convenience method to create and cleanup test files
    func withTempAudioFiles<T>(count: Int = 1, _ block: ([URL]) throws -> T) rethrows -> T {
        let urls = TestUtilities.createMockAudioFiles(count: count)
        defer { TestUtilities.cleanupTestFiles(urls) }
        return try block(urls)
    }
    
    /// Convenience method to test async operations with timeout
    func waitForAsync<T>(
        timeout: TimeInterval = 5.0,
        _ operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TimeoutError()
            }
            
            guard let result = try await group.next() else {
                throw TimeoutError()
            }
            
            group.cancelAll()
            return result
        }
    }
}

// MARK: - Custom Errors

struct TimeoutError: Error, LocalizedError {
    var errorDescription: String? {
        return "Operation timed out"
    }
}