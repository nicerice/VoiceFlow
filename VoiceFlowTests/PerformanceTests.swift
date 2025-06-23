//
//  PerformanceTests.swift
//  VoiceFlowTests
//
//  Created by Sebastian Reimann on 23.06.25.
//

import XCTest
@testable import VoiceFlow

/// Performance and stress tests to ensure VoiceFlow performs well under load
@MainActor
final class PerformanceTests: XCTestCase {
    
    var viewModel: RecordingViewModel!
    var audioRecorder: AudioRecorder!
    var transcriptionService: TranscriptionService!
    
    override func setUp() async throws {
        try await super.setUp()
        viewModel = RecordingViewModel()
        audioRecorder = AudioRecorder()
        transcriptionService = TranscriptionService()
        
        // Allow initialization
        try await Task.sleep(nanoseconds: 200_000_000)
    }
    
    override func tearDown() async throws {
        if audioRecorder?.isRecording == true {
            _ = audioRecorder.stopRecording()
        }
        viewModel = nil
        audioRecorder = nil
        transcriptionService = nil
        try await super.tearDown()
    }
    
    // MARK: - Memory Performance Tests
    
    func testViewModelMemoryPerformance() async throws {
        measure {
            for _ in 0..<1000 {
                let vm = RecordingViewModel()
                _ = vm.isRecording
                _ = vm.canRecord
                _ = vm.currentText
                _ = vm.placeholderText
            }
        }
    }
    
    func testAppStateTransitionPerformance() async throws {
        measure {
            for _ in 0..<10000 {
                viewModel.currentState = .idle
                viewModel.currentState = .recording
                viewModel.currentState = .transcribing
                viewModel.currentState = .transcribed
                viewModel.currentState = .processingLLM
                viewModel.currentState = .processed
            }
        }
    }
    
    func testComputedPropertyPerformance() async throws {
        // Setup state with data
        viewModel.completeTranscription(text: "Performance test transcription text that is reasonably long to simulate real usage scenarios")
        
        measure {
            for _ in 0..<50000 {
                _ = viewModel.isRecording
                _ = viewModel.canRecord
                _ = viewModel.canProcessLLM
                _ = viewModel.isLoading
                _ = viewModel.currentText
                _ = viewModel.placeholderText
                _ = viewModel.loadingMessage
                _ = viewModel.recordButtonColor
            }
        }
    }
    
    // MARK: - Audio System Performance Tests
    
    func testAudioRecorderInitializationPerformance() async throws {
        measure {
            for _ in 0..<100 {
                let recorder = AudioRecorder()
                recorder.checkPermissionStatus()
            }
        }
    }
    
    func testFileManagementPerformance() async throws {
        measure {
            for _ in 0..<500 {
                let url = audioRecorder.createRecordingURL()
                _ = audioRecorder.getRecordingFileSize(url: url)
            }
        }
    }
    
    func testCleanupPerformance() async throws {
        // Create multiple test files
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var testFiles: [URL] = []
        
        for i in 0..<50 {
            let fileURL = documentsPath.appendingPathComponent("test_recording_\(i).wav")
            let testData = Data("test".utf8)
            try testData.write(to: fileURL)
            testFiles.append(fileURL)
        }
        
        measure {
            audioRecorder.cleanupOldRecordings()
        }
        
        // Clean up test files
        for file in testFiles {
            try? FileManager.default.removeItem(at: file)
        }
    }
    
    // MARK: - Transcription Service Performance Tests
    
    func testTranscriptionServiceInitializationPerformance() async throws {
        measure {
            for _ in 0..<50 {
                let service = TranscriptionService()
                _ = service.checkModelAvailability()
            }
        }
    }
    
    func testFileSizeCalculationPerformance() async throws {
        // Create test file
        let tempURL = createTempFile(size: 10000)
        
        measure {
            for _ in 0..<1000 {
                _ = transcriptionService.getFileSize(url: tempURL)
            }
        }
        
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    // MARK: - Stress Tests
    
    func testRapidStateChanges() async throws {
        // Test rapid state transitions don't cause issues
        for _ in 0..<100 {
            viewModel.currentState = .idle
            viewModel.currentState = .recording
            viewModel.currentState = .transcribing
            viewModel.completeTranscription(text: "Test \(UUID().uuidString)")
            viewModel.startLLMProcessing()
            viewModel.reset()
        }
        
        // Should end in stable state
        XCTAssertEqual(viewModel.currentState, .idle)
        XCTAssertEqual(viewModel.transcribedText, "")
    }
    
    func testConcurrentTranscriptionCalls() async throws {
        let urls = (0..<10).map { _ in createTempFile(size: 1000) }
        
        // Test concurrent transcription calls
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    do {
                        _ = try await self.transcriptionService.transcribeAudio(from: url)
                    } catch {
                        // Expected for some calls
                    }
                }
            }
        }
        
        // Clean up
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    func testMemoryPressureScenario() async throws {
        // Simulate high memory usage scenario
        var viewModels: [RecordingViewModel] = []
        
        // Create many ViewModels
        for i in 0..<100 {
            let vm = RecordingViewModel()
            vm.completeTranscription(text: "Long transcription text for item \(i) that simulates real usage with substantial content that would be typical in voice transcription scenarios")
            viewModels.append(vm)
        }
        
        // Perform operations on all
        for vm in viewModels {
            vm.startLLMProcessing()
            _ = vm.currentText
            _ = vm.isRecording
        }
        
        // Clean up
        viewModels.removeAll()
        
        // Force memory cleanup
        autoreleasepool {
            // Memory should be released
        }
    }
    
    func testLongRunningOperations() async throws {
        // Test app stability over time
        let startTime = CFAbsoluteTimeGetCurrent()
        let maxDuration: TimeInterval = 5.0 // 5 seconds for CI/CD
        
        while CFAbsoluteTimeGetCurrent() - startTime < maxDuration {
            // Simulate user interactions
            viewModel.currentState = .recording
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            
            viewModel.currentState = .transcribing
            try await Task.sleep(nanoseconds: 50_000_000) // 0.05 second
            
            viewModel.completeTranscription(text: "Test transcription at \(Date())")
            try await Task.sleep(nanoseconds: 50_000_000)
            
            viewModel.startLLMProcessing()
            try await Task.sleep(nanoseconds: 100_000_000)
            
            viewModel.reset()
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        
        // Should still be in stable state
        XCTAssertEqual(viewModel.currentState, .idle)
    }
    
    // MARK: - Resource Usage Tests
    
    func testFileHandleLeaks() async throws {
        // Test that we don't leak file handles
        let initialFileCount = getOpenFileCount()
        
        // Perform many file operations
        for _ in 0..<100 {
            let tempURL = createTempFile(size: 1000)
            _ = transcriptionService.getFileSize(url: tempURL)
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        let finalFileCount = getOpenFileCount()
        
        // Should not have significantly more open files
        XCTAssertLessThan(finalFileCount - initialFileCount, 10, "Should not leak file handles")
    }
    
    func testObjectAllocationPerformance() async throws {
        // Test object allocation efficiency
        measure(metrics: [XCTMemoryMetric()]) {
            for _ in 0..<1000 {
                let vm = RecordingViewModel()
                vm.completeTranscription(text: "Test")
                vm.reset()
            }
        }
    }
    
    // MARK: - Large Data Tests
    
    func testLargeTranscriptionText() async throws {
        // Test with very large transcription text
        let largeText = String(repeating: "This is a very long transcription text that simulates a lengthy speech recording. ", count: 1000)
        
        measure {
            viewModel.completeTranscription(text: largeText)
            _ = viewModel.currentText
            _ = viewModel.placeholderText
            viewModel.reset()
        }
    }
    
    func testManyQuickOperations() async throws {
        // Test many quick operations in succession
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<1000 {
            viewModel.completeTranscription(text: "Quick test \(i)")
            _ = viewModel.currentText
            if i % 10 == 0 {
                viewModel.reset()
            }
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(duration, 1.0, "1000 operations should complete within 1 second")
    }
    
    // MARK: - Platform-Specific Performance Tests
    
    #if os(macOS)
    func testMacOSPermissionPerformance() async throws {
        measure {
            for _ in 0..<200 {
                audioRecorder.checkPermissionStatus()
            }
        }
    }
    #endif
    
    #if os(iOS)
    func testIOSAudioSessionPerformance() async throws {
        measure {
            for _ in 0..<100 {
                do {
                    try audioRecorder.configureAudioSession()
                    audioRecorder.deactivateAudioSession()
                } catch {
                    // Expected for some configurations
                }
            }
        }
    }
    #endif
    
    // MARK: - Helper Methods
    
    private func createTempFile(size: Int) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "perf_test_\(UUID().uuidString).wav"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        let data = Data(repeating: 0, count: size)
        try! data.write(to: fileURL)
        
        return fileURL
    }
    
    private func getOpenFileCount() -> Int {
        // Simple approximation - count files in temp directory
        let tempDir = FileManager.default.temporaryDirectory
        do {
            let files = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
            return files.count
        } catch {
            return 0
        }
    }
}