//
//  TestUtilities.swift
//  VoiceFlowTests
//
//  Created by Sebastian Reimann on 23.06.25.
//

import Foundation
import XCTest
@testable import VoiceFlow

@MainActor
class TestUtilities {
    
    // MARK: - Mock Data Generation
    
    static func createMockAudioFile(size: Int = 5000, name: String? = nil) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = name ?? "mock_audio_\(UUID().uuidString)"
        let fileURL = tempDir.appendingPathComponent("\(fileName).wav")
        
        let audioData = generateMockAudioData(size: size)
        try! audioData.write(to: fileURL)
        
        return fileURL
    }
    
    static func generateMockAudioData(size: Int) -> Data {
        // Create a realistic WAV file header + data
        var data = Data()
        
        // WAV file header (44 bytes)
        data.append(contentsOf: "RIFF".utf8) // ChunkID
        data.append(contentsOf: withUnsafeBytes(of: UInt32(size + 36).littleEndian) { Data($0) }) // ChunkSize
        data.append(contentsOf: "WAVE".utf8) // Format
        
        // fmt subchunk
        data.append(contentsOf: "fmt ".utf8) // Subchunk1ID
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) }) // Subchunk1Size
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) }) // AudioFormat (PCM)
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) }) // NumChannels (mono)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(44100).littleEndian) { Data($0) }) // SampleRate
        data.append(contentsOf: withUnsafeBytes(of: UInt32(88200).littleEndian) { Data($0) }) // ByteRate
        data.append(contentsOf: withUnsafeBytes(of: UInt16(2).littleEndian) { Data($0) }) // BlockAlign
        data.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian) { Data($0) }) // BitsPerSample
        
        // data subchunk
        data.append(contentsOf: "data".utf8) // Subchunk2ID
        data.append(contentsOf: withUnsafeBytes(of: UInt32(size).littleEndian) { Data($0) }) // Subchunk2Size
        
        // Generate mock audio data (sine wave)
        for i in 0..<(size / 2) {
            let sample = Int16(sin(Double(i) * 0.1) * 16383.0)
            data.append(contentsOf: withUnsafeBytes(of: sample.littleEndian) { Data($0) })
        }
        
        return data
    }
    
    static func createMockTranscriptionText(wordCount: Int = 50) -> String {
        let words = [
            "the", "quick", "brown", "fox", "jumps", "over", "lazy", "dog",
            "hello", "world", "this", "is", "a", "test", "transcription",
            "audio", "recording", "voice", "recognition", "speech", "text",
            "machine", "learning", "artificial", "intelligence", "deep",
            "neural", "network", "algorithm", "processing", "natural",
            "language", "understanding", "conversation", "dialogue"
        ]
        
        var result: [String] = []
        for _ in 0..<wordCount {
            result.append(words.randomElement() ?? "word")
        }
        
        return result.joined(separator: " ").capitalized + "."
    }
    
    static func createMockLLMResponse(inputText: String) -> String {
        let responses = [
            "Here's a refined version: \(inputText)",
            "I've processed your request: \(inputText)",
            "Based on your input, here's my response: \(inputText)",
            "Thank you for sharing. Here's what I understand: \(inputText)"
        ]
        
        return responses.randomElement() ?? "Processed: \(inputText)"
    }
    
    // MARK: - Test Helpers
    
    static func createTestViewModel(state: AppState = .idle) -> RecordingViewModel {
        let viewModel = RecordingViewModel()
        viewModel.currentState = state
        return viewModel
    }
    
    static func createTestRecorder() -> AudioRecorder {
        return AudioRecorder()
    }
    
    static func createTestTranscriptionService() -> TranscriptionService {
        return TranscriptionService()
    }
    
    // MARK: - File Management Helpers
    
    static func cleanupTestFiles(urls: [URL]) {
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    static func createTemporaryDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let testDir = tempDir.appendingPathComponent("VoiceFlowTests_\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
        return testDir
    }
    
    // MARK: - Performance Measurement
    
    static func measureTime<T>(operation: () throws -> T) rethrows -> (result: T, timeInterval: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let endTime = CFAbsoluteTimeGetCurrent()
        
        return (result: result, timeInterval: endTime - startTime)
    }
    
    static func measureAsyncTime<T>(operation: () async throws -> T) async rethrows -> (result: T, timeInterval: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let endTime = CFAbsoluteTimeGetCurrent()
        
        return (result: result, timeInterval: endTime - startTime)
    }
    
    // MARK: - Assertion Helpers
    
    static func assertEventuallyTrue(
        _ condition: @autoclosure @escaping () -> Bool,
        timeout: TimeInterval = 5.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = XCTestExpectation(description: "Condition should become true")
        
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if condition() {
                expectation.fulfill()
                timer.invalidate()
            }
        }
        
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        timer.invalidate()
        
        if result != .completed {
            XCTFail("Condition did not become true within \(timeout) seconds", file: file, line: line)
        }
    }
    
    static func assertStateTransition(
        viewModel: RecordingViewModel,
        from initialState: AppState,
        to expectedState: AppState,
        operation: () async throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async rethrows {
        viewModel.currentState = initialState
        XCTAssertEqual(viewModel.currentState, initialState, "Initial state mismatch", file: file, line: line)
        
        try await operation()
        
        XCTAssertEqual(viewModel.currentState, expectedState, "Expected state transition failed", file: file, line: line)
    }
    
    // MARK: - Mock Data Constants
    
    static let sampleTranscriptions = [
        "Hello, this is a test recording for the voice flow application.",
        "The quick brown fox jumps over the lazy dog.",
        "Testing speech recognition with various phrases and sentences.",
        "Voice input processing with artificial intelligence and machine learning.",
        "Natural language understanding and conversation processing."
    ]
    
    static let sampleLLMResponses = [
        "I understand you want to test the voice flow system.",
        "Your speech has been processed successfully.",
        "Thank you for using voice recognition technology.",
        "The AI has analyzed your voice input and generated this response.",
        "Voice processing completed with high accuracy results."
    ]
}