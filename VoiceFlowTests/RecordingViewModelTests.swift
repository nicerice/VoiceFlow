//
//  RecordingViewModelTests.swift
//  VoiceFlowTests
//
//  Created by Sebastian Reimann on 23.06.25.
//

import XCTest
@testable import VoiceFlow

@MainActor
final class RecordingViewModelTests: XCTestCase {
    
    var viewModel: RecordingViewModel!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        viewModel = RecordingViewModel()
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        try super.tearDownWithError()
    }
    
    func testInitialState() throws {
        XCTAssertEqual(viewModel.currentState, .idle)
        XCTAssertTrue(viewModel.transcribedText.isEmpty)
        XCTAssertTrue(viewModel.processedText.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.canRecord)
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertFalse(viewModel.canProcessLLM)
    }
    
    func testStartRecording() throws {
        viewModel.startRecording()
        
        // Note: The real implementation uses async/await internally
        // but the method itself is not async to the caller
        XCTAssertEqual(viewModel.currentState, .recording)
        XCTAssertTrue(viewModel.isRecording)
        XCTAssertTrue(viewModel.canRecord) // Critical: should still allow stopping
        XCTAssertFalse(viewModel.canProcessLLM)
    }
    
    func testStopRecording() throws {
        viewModel.startRecording()
        XCTAssertEqual(viewModel.currentState, .recording)
        
        // Simulate stopping recording (the actual method is not async in the real implementation)
        viewModel.stopRecording()
        // Note: The real implementation immediately transitions to .transcribing
        // but we can't easily test the async transcription completion here
    }
    
    func testCompleteTranscription() throws {
        let testText = "Hello, this is a test transcription"
        viewModel.completeTranscription(text: testText)
        
        XCTAssertEqual(viewModel.currentState, .transcribed)
        XCTAssertEqual(viewModel.transcribedText, testText)
        XCTAssertTrue(viewModel.canProcessLLM)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.canRecord)
    }
    
    func testStartLLMProcessing() throws {
        // Setup transcribed state
        viewModel.completeTranscription(text: "Test input")
        XCTAssertTrue(viewModel.canProcessLLM)
        
        viewModel.startLLMProcessing()
        XCTAssertEqual(viewModel.currentState, .processingLLM)
        XCTAssertTrue(viewModel.isLoading)
        XCTAssertFalse(viewModel.canProcessLLM)
        XCTAssertFalse(viewModel.canRecord)
    }
    
    func testCompleteLLMProcessing() throws {
        let testResult = "This is the LLM processed result"
        viewModel.completeLLMProcessing(text: testResult)
        
        XCTAssertEqual(viewModel.currentState, .processed)
        XCTAssertEqual(viewModel.processedText, testResult)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.canRecord)
        XCTAssertTrue(viewModel.canProcessLLM) // processed state allows LLM processing again
    }
    
    func testHandleError() throws {
        let error = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        viewModel.handleError(error)
        
        // Error handling resets to previous stable state, not a dedicated error state
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.showError)
    }
    
    func testReset() throws {
        // Setup some state
        viewModel.completeTranscription(text: "Test")
        viewModel.completeLLMProcessing(text: "Result")
        
        viewModel.reset()
        
        XCTAssertEqual(viewModel.currentState, .idle)
        XCTAssertTrue(viewModel.transcribedText.isEmpty)
        XCTAssertTrue(viewModel.processedText.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.canRecord)
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertFalse(viewModel.canProcessLLM)
    }
    
    func testFullWorkflow() throws {
        // Test complete workflow
        viewModel.startRecording()
        XCTAssertEqual(viewModel.currentState, .recording)
        
        // Skip stopping since it triggers async transcription
        // Instead test direct state transitions
        viewModel.completeTranscription(text: "Test transcription")
        XCTAssertEqual(viewModel.currentState, .transcribed)
        XCTAssertTrue(viewModel.canProcessLLM)
        
        viewModel.startLLMProcessing()
        XCTAssertEqual(viewModel.currentState, .processingLLM)
        
        viewModel.completeLLMProcessing(text: "Final result")
        XCTAssertEqual(viewModel.currentState, .processed)
        XCTAssertEqual(viewModel.processedText, "Final result")
    }
    
    func testStateConsistency() throws {
        // Test that computed properties are consistent with state
        let states: [AppState] = [.idle, .recording, .transcribing, .transcribed, .processingLLM, .processed]
        
        for state in states {
            viewModel.currentState = state
            
            XCTAssertEqual(viewModel.isLoading, state.isLoading, "isLoading mismatch for state \(state)")
            XCTAssertEqual(viewModel.canRecord, state.canRecord, "canRecord mismatch for state \(state)")
            XCTAssertEqual(viewModel.isRecording, state.isRecording, "isRecording mismatch for state \(state)")
            // Note: viewModel.canProcessLLM also checks for non-empty text, so we can't directly compare
        }
    }
    
    func testPerformanceOfComputedProperties() throws {
        // Performance test for computed properties
        measure {
            for _ in 0..<1000 {
                _ = viewModel.isLoading
                _ = viewModel.canRecord
                _ = viewModel.isRecording
                _ = viewModel.canProcessLLM
            }
        }
    }
    
    func testCriticalStopButtonFix() throws {
        // This test validates the critical fix for stop button responsiveness
        viewModel.startRecording()
        
        // While recording, the record button should still be enabled to allow stopping
        XCTAssertTrue(viewModel.canRecord, "CRITICAL: Record button must remain enabled during recording to allow stopping")
        XCTAssertTrue(viewModel.isRecording, "Should be in recording state")
        
        // User should be able to stop recording
        viewModel.stopRecording()
        XCTAssertFalse(viewModel.isRecording, "Should no longer be recording after stop")
        XCTAssertEqual(viewModel.currentState, .transcribing, "Should transition to transcribing after stop")
    }
}