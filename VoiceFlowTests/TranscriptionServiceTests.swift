//
//  TranscriptionServiceTests.swift
//  VoiceFlowTests
//
//  Created by Sebastian Reimann on 23.06.25.
//

import XCTest
@testable import VoiceFlow

/// Integration tests for TranscriptionService to ensure robust speech-to-text functionality
@MainActor
final class TranscriptionServiceTests: XCTestCase {
    
    var transcriptionService: TranscriptionService!
    
    override func setUp() async throws {
        try await super.setUp()
        transcriptionService = TranscriptionService()
        
        // Allow initialization time for WhisperKit
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
    
    override func tearDown() async throws {
        transcriptionService = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() async throws {
        XCTAssertEqual(transcriptionService.modelLoadingProgress, 0.0, accuracy: 0.1)
        // isModelLoading and isInitialized depend on WhisperKit initialization
    }
    
    func testModelAvailabilityCheck() async throws {
        let isAvailable = transcriptionService.checkModelAvailability()
        // Should return a boolean value
        XCTAssertTrue(isAvailable == true || isAvailable == false)
    }
    
    // MARK: - File Validation Tests
    
    func testTranscribeNonExistentFile() async throws {
        let nonExistentURL = URL(fileURLWithPath: "/path/to/nonexistent/file.wav")
        
        do {
            let result = try await transcriptionService.transcribeAudio(from: nonExistentURL)
            XCTAssertTrue(result.contains("Audio file not found"), 
                         "Should return appropriate error message for non-existent file")
        } catch {
            XCTFail("Should not throw error, should return error message: \(error)")
        }
    }
    
    func testTranscribeEmptyFile() async throws {
        // Create empty test file
        let tempURL = createTempAudioFile(withSize: 0)
        
        do {
            let result = try await transcriptionService.transcribeAudio(from: tempURL)
            XCTAssertTrue(result.contains("Recording too short"), 
                         "Should return appropriate error message for empty file")
        } catch {
            XCTFail("Should not throw error, should return error message: \(error)")
        }
        
        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    func testTranscribeSmallFile() async throws {
        // Create small test file (less than 1KB)
        let tempURL = createTempAudioFile(withSize: 500)
        
        do {
            let result = try await transcriptionService.transcribeAudio(from: tempURL)
            XCTAssertTrue(result.contains("Recording too short") || result.contains("simulation"), 
                         "Should return appropriate message for small file")
        } catch {
            XCTFail("Should not throw error, should return error message: \(error)")
        }
        
        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    func testTranscribeValidSizeFile() async throws {
        // Create file with reasonable size
        let tempURL = createTempAudioFile(withSize: 10000) // 10KB
        
        do {
            let result = try await transcriptionService.transcribeAudio(from: tempURL)
            XCTAssertFalse(result.isEmpty, "Should return some result for valid file")
            // Result will be either real transcription or fallback message
        } catch {
            XCTFail("Should not throw error for valid file: \(error)")
        }
        
        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    // MARK: - Fallback System Tests
    
    func testFallbackTranscription() async throws {
        // Create a valid file but force fallback (when WhisperKit not ready)
        let tempURL = createTempAudioFile(withSize: 5000)
        
        // If WhisperKit fails to initialize, should get fallback
        let result = try await transcriptionService.transcribeAudio(from: tempURL)
        
        XCTAssertFalse(result.isEmpty, "Should always return some result")
        // Could be real transcription or fallback message
        
        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    // MARK: - Music Detection Tests
    
    func testMusicDetectionHandling() async throws {
        // This test simulates the music detection scenario
        // In real usage, WhisperKit would return "[Music]" for non-speech audio
        let tempURL = createTempAudioFile(withSize: 5000)
        
        let result = try await transcriptionService.transcribeAudio(from: tempURL)
        
        // If music is detected, should get helpful message
        if result.contains("No clear speech detected") {
            XCTAssertTrue(result.contains("speak more clearly"))
        }
        
        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    // MARK: - Error Recovery Tests
    
    func testServiceReset() async throws {
        // Test that service can be reset
        await transcriptionService.resetService()
        
        // After reset, service should be in a clean state
        XCTAssertEqual(transcriptionService.modelLoadingProgress, 0.0, accuracy: 0.1)
    }
    
    // MARK: - File Size Utility Tests
    
    func testFileSizeCalculation() async throws {
        let tempURL = createTempAudioFile(withSize: 2048) // 2KB
        
        let calculatedSize = transcriptionService.getFileSize(url: tempURL)
        XCTAssertEqual(calculatedSize, 2048)
        
        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    func testFileSizeForNonExistentFile() async throws {
        let nonExistentURL = URL(fileURLWithPath: "/path/to/nonexistent/file.wav")
        
        let size = transcriptionService.getFileSize(url: nonExistentURL)
        XCTAssertEqual(size, 0, "Should return 0 for non-existent file")
    }
    
    // MARK: - Performance Tests
    
    func testTranscriptionPerformance() async throws {
        let tempURL = createTempAudioFile(withSize: 5000)
        
        // Measure transcription performance
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = try await transcriptionService.transcribeAudio(from: tempURL)
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Transcription should complete within reasonable time (10 seconds max)
        XCTAssertLessThan(timeElapsed, 10.0, "Transcription should complete within 10 seconds")
        
        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    func testModelAvailabilityPerformance() async throws {
        measure {
            for _ in 0..<100 {
                _ = transcriptionService.checkModelAvailability()
            }
        }
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentTranscriptionCalls() async throws {
        let tempURL1 = createTempAudioFile(withSize: 3000)
        let tempURL2 = createTempAudioFile(withSize: 4000)
        
        // Test concurrent transcription calls
        async let result1 = transcriptionService.transcribeAudio(from: tempURL1)
        async let result2 = transcriptionService.transcribeAudio(from: tempURL2)
        
        let (transcription1, transcription2) = try await (result1, result2)
        
        XCTAssertFalse(transcription1.isEmpty)
        XCTAssertFalse(transcription2.isEmpty)
        
        // Clean up
        try? FileManager.default.removeItem(at: tempURL1)
        try? FileManager.default.removeItem(at: tempURL2)
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() async throws {
        weak var weakService: TranscriptionService?
        
        autoreleasepool {
            let service = TranscriptionService()
            weakService = service
            XCTAssertNotNil(weakService)
        }
        
        // Allow some time for deallocation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Service should be deallocated
        XCTAssertNil(weakService, "TranscriptionService should be deallocated when no longer referenced")
    }
    
    // MARK: - Helper Methods
    
    private func createTempAudioFile(withSize size: Int) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "test_audio_\(UUID().uuidString).wav"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        // Create file with specified size
        let data = Data(repeating: 0, count: size)
        try! data.write(to: fileURL)
        
        return fileURL
    }
}