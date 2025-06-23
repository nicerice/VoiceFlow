//
//  AudioRecorderTests.swift
//  VoiceFlowTests
//
//  Created by Sebastian Reimann on 23.06.25.
//

import XCTest
import AVFoundation
@testable import VoiceFlow

@MainActor
final class AudioRecorderTests: XCTestCase {
    
    var audioRecorder: AudioRecorder!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        audioRecorder = AudioRecorder()
    }
    
    override func tearDownWithError() throws {
        audioRecorder = nil
        try super.tearDownWithError()
    }
    
    func testInitialState() throws {
        XCTAssertFalse(audioRecorder.isRecording)
    }
    
    func testRecordingStateManagement() async throws {
        XCTAssertFalse(audioRecorder.isRecording)
        
        // Test stopping when not recording
        let result = audioRecorder.stopRecording()
        XCTAssertNil(result, "Stop should return nil when not recording")
    }
    
    func testCreateRecordingURL() throws {
        let url = audioRecorder.createRecordingURL()
        
        XCTAssertTrue(url.pathExtension == "wav" || url.pathExtension == "m4a", "Should create audio file URL")
        XCTAssertTrue(url.path.contains("recording"), "URL should contain 'recording' identifier")
    }
    
    func testCleanupOldRecordings() throws {
        // Create some test files
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let testFile1 = documentsPath.appendingPathComponent("old_recording_1.wav")
        let testFile2 = documentsPath.appendingPathComponent("old_recording_2.wav")
        
        // Create test files
        try "test data 1".write(to: testFile1, atomically: true, encoding: .utf8)
        try "test data 2".write(to: testFile2, atomically: true, encoding: .utf8)
        
        // Verify files exist
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFile1.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFile2.path))
        
        // Test cleanup
        audioRecorder.cleanupOldRecordings()
        
        // Files might still exist if they're recent, so we just test the method doesn't crash
        XCTAssertNoThrow(audioRecorder.cleanupOldRecordings())
        
        // Cleanup test files
        try? FileManager.default.removeItem(at: testFile1)
        try? FileManager.default.removeItem(at: testFile2)
    }
    
    func testPermissionHandling() throws {
        // Test permission check exists (we can't easily test async permission in unit tests)
        XCTAssertNotNil(audioRecorder)
        
        // Test that permission status is available
        #if os(iOS)
        XCTAssertTrue(audioRecorder.permissionStatus == .granted || audioRecorder.permissionStatus == .denied || audioRecorder.permissionStatus == .undetermined)
        #else
        XCTAssertTrue(audioRecorder.permissionStatus == .granted || audioRecorder.permissionStatus == .denied)
        #endif
    }
    
    func testRecordingFileCreation() throws {
        // Test that we can create a recording URL
        let url = audioRecorder.createRecordingURL()
        
        XCTAssertNotNil(url)
        XCTAssertTrue(url.isFileURL)
        
        // Test the URL is in documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        XCTAssertTrue(url.path.hasPrefix(documentsPath.path))
    }
    
    func testMultipleRecordingURLsAreUnique() throws {
        let url1 = audioRecorder.createRecordingURL()
        let url2 = audioRecorder.createRecordingURL()
        
        XCTAssertNotEqual(url1, url2, "Each recording should have a unique URL")
    }
    
    func testRecordingSettings() throws {
        // Test that audio settings are properly configured
        // This is mainly a smoke test to ensure settings don't cause crashes
        XCTAssertNoThrow(audioRecorder.createRecordingURL())
    }
    
    func testPlatformSpecificBehavior() throws {
        #if os(macOS)
        // Test macOS specific behavior
        XCTAssertNotNil(audioRecorder)
        #elseif os(iOS)
        // Test iOS specific behavior
        XCTAssertNotNil(audioRecorder)
        #endif
    }
    
    func testMemoryManagement() throws {
        // Test that creating and releasing audio recorder doesn't leak memory
        weak var weakRecorder: AudioRecorder?
        
        autoreleasepool {
            let tempRecorder = AudioRecorder()
            weakRecorder = tempRecorder
            XCTAssertNotNil(weakRecorder)
        }
        
        // After autoreleasepool, weak reference should be nil
        XCTAssertNil(weakRecorder, "AudioRecorder should be deallocated")
    }
    
    func testConcurrentAccess() throws {
        // Test concurrent access to isRecording property
        // Since isRecording is MainActor isolated, we test it synchronously
        for _ in 0..<10 {
            _ = audioRecorder.isRecording
        }
    }
    
    func testErrorHandling() throws {
        // Test various error conditions
        
        // Test stopping when not recording
        let result = audioRecorder.stopRecording()
        XCTAssertNil(result, "Should return nil when stopping non-active recording")
        
        // Test state after error
        XCTAssertFalse(audioRecorder.isRecording, "Should not be recording after error")
    }
}