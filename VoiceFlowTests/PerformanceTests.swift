//
//  PerformanceTests.swift
//  VoiceFlowTests
//
//  Created by Sebastian Reimann on 23.06.25.
//

import XCTest
@testable import VoiceFlow

@MainActor
final class PerformanceTests: XCTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
    
    func testViewModelCreationPerformance() throws {
        measure {
            for _ in 0..<100 {
                let viewModel = RecordingViewModel()
                _ = viewModel.currentState
            }
        }
    }
    
    func testStateTransitionPerformance() throws {
        let viewModel = RecordingViewModel()
        
        measure {
            for _ in 0..<1000 {
                viewModel.currentState = .idle
                viewModel.currentState = .recording
                viewModel.currentState = .transcribing
                viewModel.currentState = .transcribed
                viewModel.currentState = .processingLLM
                viewModel.currentState = .processed
                // Skip .error since it doesn't exist
            }
        }
    }
    
    func testComputedPropertiesPerformance() throws {
        let viewModel = RecordingViewModel()
        
        measure {
            for _ in 0..<10000 {
                _ = viewModel.isLoading
                _ = viewModel.canRecord
                _ = viewModel.isRecording
                _ = viewModel.canProcessLLM
            }
        }
    }
    
    func testAudioRecorderCreationPerformance() throws {
        measure {
            for _ in 0..<50 {
                let recorder = AudioRecorder()
                _ = recorder.isRecording
            }
        }
    }
    
    func testTranscriptionServiceCreationPerformance() throws {
        measure {
            for _ in 0..<10 {
                let service = TranscriptionService()
                _ = service
            }
        }
    }
    
    func testFileURLCreationPerformance() throws {
        let recorder = AudioRecorder()
        
        measure {
            for _ in 0..<1000 {
                _ = recorder.createRecordingURL()
            }
        }
    }
    
    func testFileSizeCalculationPerformance() throws {
        let service = TranscriptionService()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("perf_test.wav")
        let testData = Data(repeating: 0, count: 10240) // 10KB test file
        try testData.write(to: tempURL)
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        measure {
            for _ in 0..<1000 {
                _ = service.getFileSize(url: tempURL)
            }
        }
    }
    
    func testMemoryPressureScenario() async throws {
        // Test app behavior under memory pressure
        var viewModels: [RecordingViewModel] = []
        
        // Create many ViewModels to simulate memory pressure
        for i in 0..<100 {
            let vm = RecordingViewModel()
            vm.completeTranscription(text: "Long transcription text for item \(i) with lots of content to use memory")
            vm.completeLLMProcessing(text: "Processed result for item \(i) with even more content")
            viewModels.append(vm)
        }
        
        // Test that the app still functions
        let newViewModel = RecordingViewModel()
        newViewModel.startRecording()
        XCTAssertEqual(newViewModel.currentState, .recording)
        
        // Clean up
        viewModels.removeAll()
    }
    
    func testConcurrentStateUpdates() async throws {
        let viewModel = RecordingViewModel()
        
        // Test concurrent state updates
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask { @MainActor in
                    viewModel.completeTranscription(text: "Concurrent text \(i)")
                    viewModel.completeLLMProcessing(text: "Concurrent result \(i)")
                    viewModel.reset()
                }
            }
        }
        
        // Should still be in a valid state
        XCTAssertEqual(viewModel.currentState, .idle)
    }
    
    func testLargeFileHandling() throws {
        let service = TranscriptionService()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("large_test.wav")
        
        // Create a larger test file (1MB)
        let largeData = Data(repeating: 0, count: 1024 * 1024)
        try largeData.write(to: tempURL)
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        measure {
            _ = service.getFileSize(url: tempURL)
        }
    }
    
    func testUIResponsivenessUnderLoad() async throws {
        let viewModel = RecordingViewModel()
        
        // Simulate heavy UI updates
        measure {
            for i in 0..<100 {
                viewModel.completeTranscription(text: "Transcription \(i)")
                _ = viewModel.isLoading
                _ = viewModel.canRecord
                _ = viewModel.transcribedText
                
                viewModel.completeLLMProcessing(text: "Result \(i)")
                _ = viewModel.processedText
                _ = viewModel.canProcessLLM
                
                viewModel.reset()
            }
        }
    }
    
    func testMemoryLeakDetection() throws {
        // Test for potential memory leaks
        weak var weakRecorder: AudioRecorder?
        weak var weakService: TranscriptionService?
        
        autoreleasepool {
            let recorder = AudioRecorder()
            let service = TranscriptionService()
            
            weakRecorder = recorder
            weakService = service
            
            // Use the objects
            _ = recorder.createRecordingURL()
            _ = service.getFileSize(url: URL(fileURLWithPath: "/tmp/test.wav"))
        }
        
        // Objects should be deallocated
        XCTAssertNil(weakRecorder, "AudioRecorder should not leak memory")
        XCTAssertNil(weakService, "TranscriptionService should not leak memory")
    }
    
    func testStressTestStateTransitions() throws {
        let viewModel = RecordingViewModel()
        
        // Stress test with many rapid state transitions
        for _ in 0..<100 { // Reduced for performance
            viewModel.startRecording()
            viewModel.completeTranscription(text: "Test")
            viewModel.startLLMProcessing()
            viewModel.completeLLMProcessing(text: "Result")
            viewModel.reset()
        }
        
        // Should end in a valid state
        XCTAssertEqual(viewModel.currentState, .idle)
        XCTAssertTrue(viewModel.transcribedText.isEmpty)
        XCTAssertTrue(viewModel.processedText.isEmpty)
    }
    
    func testConcurrentFileOperations() async throws {
        let recorder = AudioRecorder()
        
        // Test concurrent file operations
        await withTaskGroup(of: URL.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    return await recorder.createRecordingURL()
                }
            }
            
            var urls: Set<URL> = []
            for await url in group {
                urls.insert(url)
            }
            
            // All URLs should be unique
            XCTAssertEqual(urls.count, 20, "All URLs should be unique")
        }
    }
}