//
//  VoiceFlowTests.swift
//  VoiceFlowTests
//
//  Created by Sebastian Reimann on 23.06.25.
//

import XCTest
@testable import VoiceFlow

@MainActor
final class VoiceFlowTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    func testAppStateEnum() throws {
        // Test that AppState enum is properly defined
        let states: [AppState] = [.idle, .recording, .transcribing, .transcribed, .processingLLM, .processed]
        XCTAssertEqual(states.count, 6, "Should have 6 app states")
    }
    
    func testRecordingViewModelInitialization() throws {
        let viewModel = RecordingViewModel()
        XCTAssertEqual(viewModel.currentState, .idle)
        XCTAssertTrue(viewModel.transcribedText.isEmpty)
        XCTAssertTrue(viewModel.processedText.isEmpty)
    }
    
    func testAudioRecorderInitialization() throws {
        let recorder = AudioRecorder()
        XCTAssertFalse(recorder.isRecording)
    }
    
    func testTranscriptionServiceInitialization() throws {
        let service = TranscriptionService()
        XCTAssertNotNil(service)
    }
    
    func testBasicWorkflow() throws {
        let viewModel = RecordingViewModel()
        
        // Start with idle state
        XCTAssertEqual(viewModel.currentState, .idle)
        
        // Start recording
        viewModel.startRecording()
        XCTAssertEqual(viewModel.currentState, .recording)
        
        // Complete transcription (skip stop recording due to async complexity)
        viewModel.completeTranscription(text: "Test transcription")
        XCTAssertEqual(viewModel.currentState, .transcribed)
        XCTAssertEqual(viewModel.transcribedText, "Test transcription")
    }
    
    func testFileCreation() throws {
        let recorder = AudioRecorder()
        let url = recorder.createRecordingURL()
        
        XCTAssertTrue(url.isFileURL)
        XCTAssertTrue(url.path.contains("recording"))
    }
    
    func testMockDataGeneration() throws {
        let audioURL = TestUtilities.createMockAudioFile()
        XCTAssertTrue(FileManager.default.fileExists(atPath: audioURL.path))
        
        let transcriptionText = TestUtilities.createMockTranscriptionText(wordCount: 10)
        XCTAssertFalse(transcriptionText.isEmpty)
        XCTAssertTrue(transcriptionText.split(separator: " ").count >= 5)
        
        // Cleanup
        try? FileManager.default.removeItem(at: audioURL)
    }
    
    func testStateConsistency() throws {
        let viewModel = RecordingViewModel()
        
        // Test each state has consistent properties
        for state in [AppState.idle, .recording, .transcribing, .transcribed, .processingLLM, .processed] {
            viewModel.currentState = state
            
            // Computed properties should match state properties
            XCTAssertEqual(viewModel.isLoading, state.isLoading)
            XCTAssertEqual(viewModel.canRecord, state.canRecord)
            XCTAssertEqual(viewModel.isRecording, state.isRecording)
            // Note: viewModel.canProcessLLM also checks for text content
        }
    }
    
    func testCriticalStopButtonFix() throws {
        // This test validates the critical fix for the stop button
        let recordingState = AppState.recording
        
        // CRITICAL: Recording state must allow canRecord to be true for stop button
        XCTAssertTrue(recordingState.canRecord, "CRITICAL: Recording state must allow canRecord=true for stop button")
        XCTAssertTrue(recordingState.isRecording, "Recording state should have isRecording=true")
    }
    
    func testErrorHandling() throws {
        let viewModel = RecordingViewModel()
        let error = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        // Test error handling
        viewModel.handleError(error)
        XCTAssertNotNil(viewModel.error, "Should store the error")
        XCTAssertTrue(viewModel.showError, "Should show error state")
    }
    
    func testPerformanceOfCoreOperations() throws {
        measure {
            for _ in 0..<100 {
                let recorder = AudioRecorder()
                _ = recorder.createRecordingURL()
            }
        }
    }
    
    func testFullIntegrationWorkflow() throws {
        let viewModel = RecordingViewModel()
        
        // Complete workflow test
        viewModel.startRecording()
        XCTAssertEqual(viewModel.currentState, .recording)
        
        viewModel.completeTranscription(text: "Integration test transcription")
        XCTAssertEqual(viewModel.currentState, .transcribed)
        XCTAssertTrue(viewModel.canProcessLLM)
        
        viewModel.startLLMProcessing()
        XCTAssertEqual(viewModel.currentState, .processingLLM)
        
        viewModel.completeLLMProcessing(text: "Integration test result")
        XCTAssertEqual(viewModel.currentState, .processed)
        XCTAssertEqual(viewModel.processedText, "Integration test result")
        
        // Reset to start again
        viewModel.reset()
        XCTAssertEqual(viewModel.currentState, .idle)
        XCTAssertTrue(viewModel.transcribedText.isEmpty)
        XCTAssertTrue(viewModel.processedText.isEmpty)
    }
}
