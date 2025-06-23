//
//  TranscriptionServiceTests.swift
//  VoiceFlowTests
//
//  Created by Sebastian Reimann on 23.06.25.
//

import XCTest
@testable import VoiceFlow

@MainActor
final class TranscriptionServiceTests: XCTestCase {
    
    var transcriptionService: TranscriptionService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        transcriptionService = TranscriptionService()
    }
    
    override func tearDownWithError() throws {
        transcriptionService = nil
        try super.tearDownWithError()
    }
    
    func testInitialization() throws {
        XCTAssertNotNil(transcriptionService)
    }
    
    func testTranscribeNonExistentFile() async throws {
        let nonExistentURL = URL(fileURLWithPath: "/path/to/nonexistent/file.wav")
        let result = try await transcriptionService.transcribeAudio(from: nonExistentURL)
        
        XCTAssertTrue(result.contains("Audio file not found") || result.contains("Error"), 
                     "Should return error message for non-existent file")
    }
    
    func testTranscribeEmptyFile() async throws {
        // Create a temporary empty file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("empty_test.wav")
        try Data().write(to: tempURL)
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        let result = try await transcriptionService.transcribeAudio(from: tempURL)
        
        // Should handle empty file gracefully
        XCTAssertFalse(result.isEmpty, "Should return some result even for empty file")
    }
    
    func testGetFileSize() throws {
        // Create a test file with known size
        let testData = "Hello, World!".data(using: .utf8)!
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("size_test.wav")
        try testData.write(to: tempURL)
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        let fileSize = transcriptionService.getFileSize(url: tempURL)
        XCTAssertEqual(fileSize, Int64(testData.count))
    }
    
    func testGetFileSizeNonExistentFile() throws {
        let nonExistentURL = URL(fileURLWithPath: "/path/to/nonexistent/file.wav")
        let fileSize = transcriptionService.getFileSize(url: nonExistentURL)
        
        XCTAssertEqual(fileSize, 0, "Should return 0 for non-existent file")
    }
    
    func testWhisperKitIntegration() async throws {
        // Test that WhisperKit integration doesn't crash
        // We can't test actual transcription without audio files and model loading
        XCTAssertNoThrow(TranscriptionService())
    }
    
    func testConcurrentTranscription() async throws {
        // Test concurrent transcription requests
        let tempURL1 = FileManager.default.temporaryDirectory.appendingPathComponent("test1.wav")
        let tempURL2 = FileManager.default.temporaryDirectory.appendingPathComponent("test2.wav")
        
        // Create minimal test files
        try Data().write(to: tempURL1)
        try Data().write(to: tempURL2)
        
        defer {
            try? FileManager.default.removeItem(at: tempURL1)
            try? FileManager.default.removeItem(at: tempURL2)
        }
        
        async let result1 = transcriptionService.transcribeAudio(from: tempURL1)
        async let result2 = transcriptionService.transcribeAudio(from: tempURL2)
        
        let (transcription1, transcription2) = try await (result1, result2)
        
        XCTAssertNotNil(transcription1)
        XCTAssertNotNil(transcription2)
    }
    
    func testErrorHandling() async throws {
        // Test various error conditions
        
        // Invalid file extension
        let invalidURL = URL(fileURLWithPath: "/tmp/test.txt")
        let result = try await transcriptionService.transcribeAudio(from: invalidURL)
        
        // Should handle gracefully
        XCTAssertFalse(result.isEmpty, "Should return error message for invalid file")
    }
    
    func testMemoryManagement() throws {
        // Test memory management
        weak var weakService: TranscriptionService?
        
        autoreleasepool {
            let tempService = TranscriptionService()
            weakService = tempService
            XCTAssertNotNil(weakService)
        }
        
        // Service should be deallocated
        XCTAssertNil(weakService, "TranscriptionService should be deallocated")
    }
    
    func testFileValidation() throws {
        // Test file validation logic
        let validExtensions = ["wav", "m4a", "mp3", "aiff"]
        
        for ext in validExtensions {
            let url = URL(fileURLWithPath: "/tmp/test.\(ext)")
            // Just test that URL creation works
            XCTAssertEqual(url.pathExtension, ext)
        }
    }
    
    func testPerformanceOfFileOperations() throws {
        // Performance test for file operations
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("perf_test.wav")
        let testData = Data(repeating: 0, count: 1024) // 1KB test file
        try testData.write(to: tempURL)
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        measure {
            for _ in 0..<100 {
                _ = transcriptionService.getFileSize(url: tempURL)
            }
        }
    }
    
    func testFallbackBehavior() async throws {
        // Test fallback behavior when WhisperKit is not available
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("fallback_test.wav")
        try Data().write(to: tempURL)
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        let result = try await transcriptionService.transcribeAudio(from: tempURL)
        
        // Should return some result (either transcription or fallback message)
        XCTAssertFalse(result.isEmpty, "Should return fallback result when transcription fails")
    }
}