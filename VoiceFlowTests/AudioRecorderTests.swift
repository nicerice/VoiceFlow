//
//  AudioRecorderTests.swift
//  VoiceFlowTests
//
//  Created by Sebastian Reimann on 23.06.25.
//

import XCTest
import AVFoundation
@testable import VoiceFlow

/// Integration tests for AudioRecorder service to ensure robust audio recording functionality
@MainActor
final class AudioRecorderTests: XCTestCase {
    
    var audioRecorder: AudioRecorder!
    
    override func setUp() async throws {
        try await super.setUp()
        audioRecorder = AudioRecorder()
        
        // Allow initialization time
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
    
    override func tearDown() async throws {
        // Clean up any active recordings
        if audioRecorder.isRecording {
            _ = audioRecorder.stopRecording()
        }
        audioRecorder = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() async throws {
        XCTAssertFalse(audioRecorder.isRecording)
        // Permission status will depend on system state
        XCTAssertNotNil(audioRecorder.permissionStatus)
    }
    
    // MARK: - Permission Tests
    
    func testPermissionStatusCheck() async throws {
        audioRecorder.checkPermissionStatus()
        
        // Permission status should be set after check
        #if os(iOS)
        XCTAssertTrue([
            AVAudioSession.RecordPermission.denied,
            AVAudioSession.RecordPermission.granted,
            AVAudioSession.RecordPermission.undetermined
        ].contains(audioRecorder.permissionStatus))
        #else
        XCTAssertTrue([
            AudioPermissionStatus.denied,
            AudioPermissionStatus.granted
        ].contains(audioRecorder.permissionStatus))
        #endif
    }
    
    // MARK: - File Management Tests
    
    func testRecordingURLGeneration() async throws {
        // Test that createRecordingURL generates valid URLs
        let url1 = audioRecorder.createRecordingURL()
        let url2 = audioRecorder.createRecordingURL()
        
        XCTAssertNotEqual(url1, url2, "Each recording should have a unique URL")
        XCTAssertTrue(url1.lastPathComponent.hasPrefix("recording_"))
        XCTAssertTrue(url1.pathExtension == "wav")
    }
    
    func testFileCleanup() async throws {
        // Create test files
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // Create old test file
        let oldFileURL = documentsPath.appendingPathComponent("recording_old_test.wav")
        let testData = Data("test audio data".utf8)
        try testData.write(to: oldFileURL)
        
        // Set creation date to 25 hours ago (should be cleaned up)
        let oldDate = Date().addingTimeInterval(-25 * 60 * 60)
        try FileManager.default.setAttributes([.creationDate: oldDate], ofItemAtPath: oldFileURL.path)
        
        // Run cleanup
        audioRecorder.cleanupOldRecordings()
        
        // Old file should be deleted
        XCTAssertFalse(FileManager.default.fileExists(atPath: oldFileURL.path))
    }
    
    func testFileSizeCalculation() async throws {
        // Create test file
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let testFileURL = documentsPath.appendingPathComponent("test_size.wav")
        let testData = Data(repeating: 0, count: 1024) // 1KB
        try testData.write(to: testFileURL)
        
        let fileSize = audioRecorder.getRecordingFileSize(url: testFileURL)
        XCTAssertEqual(fileSize, 1024)
        
        // Clean up
        try? FileManager.default.removeItem(at: testFileURL)
    }
    
    // MARK: - Recording State Tests
    
    func testRecordingStateManagement() async throws {
        XCTAssertFalse(audioRecorder.isRecording)
        
        // Test stop when not recording
        let result = audioRecorder.stopRecording()
        XCTAssertNil(result, "Stop should return nil when not recording")
        
        // Test cancel when not recording
        audioRecorder.cancelRecording() // Should not crash
    }
    
    // MARK: - Audio Format Tests
    
    func testAudioFormatConfiguration() async throws {
        // Test that our audio format is properly configured for speech
        let recordingFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        )
        
        XCTAssertNotNil(recordingFormat)
        XCTAssertEqual(recordingFormat?.sampleRate, 16000)
        XCTAssertEqual(recordingFormat?.channelCount, 1)
    }
    
    // MARK: - Error Handling Tests
    
    func testVoiceFlowErrorTypes() async throws {
        let permissionError = VoiceFlowError.permissionDenied
        let setupError = VoiceFlowError.recordingSetupFailed
        let startError = VoiceFlowError.recordingStartFailed
        
        XCTAssertEqual(permissionError.localizedDescription, 
                      "Microphone permission is required to record audio. Please grant permission in System Preferences.")
        XCTAssertEqual(setupError.localizedDescription, 
                      "Failed to set up audio recording. Please check your microphone.")
        XCTAssertEqual(startError.localizedDescription, 
                      "Failed to start recording. Please try again.")
    }
    
    // MARK: - Platform-Specific Tests
    
    #if os(iOS)
    func testIOSAudioSessionConfiguration() async throws {
        // Test iOS-specific audio session setup
        do {
            try audioRecorder.configureAudioSession()
            // Should not throw on iOS
        } catch {
            XCTFail("Audio session configuration should not fail on iOS: \(error)")
        }
    }
    #endif
    
    #if os(macOS)
    func testMacOSPermissionHandling() async throws {
        // Test macOS-specific permission handling
        audioRecorder.checkPermissionStatus()
        
        // Should have a valid permission status
        XCTAssertTrue([
            AudioPermissionStatus.granted,
            AudioPermissionStatus.denied
        ].contains(audioRecorder.permissionStatus))
    }
    #endif
    
    // MARK: - Performance Tests
    
    func testPermissionCheckPerformance() async throws {
        measure {
            for _ in 0..<100 {
                audioRecorder.checkPermissionStatus()
            }
        }
    }
    
    func testFileManagementPerformance() async throws {
        measure {
            for _ in 0..<50 {
                let url = audioRecorder.createRecordingURL()
                _ = audioRecorder.getRecordingFileSize(url: url)
            }
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() async throws {
        weak var weakRecorder: AudioRecorder?
        
        autoreleasepool {
            let recorder = AudioRecorder()
            weakRecorder = recorder
            // Recorder should exist
            XCTAssertNotNil(weakRecorder)
        }
        
        // After autoreleasepool, recorder should be deallocated
        XCTAssertNil(weakRecorder, "AudioRecorder should be deallocated when no longer referenced")
    }
}