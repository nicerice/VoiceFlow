//
//  RecordingViewModelTests.swift
//  VoiceFlowTests
//
//  Created by Sebastian Reimann on 23.06.25.
//

import XCTest
@testable import VoiceFlow

/// Comprehensive tests for RecordingViewModel to ensure proper state management and business logic
@MainActor
final class RecordingViewModelTests: XCTestCase {
    
    var viewModel: RecordingViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        viewModel = RecordingViewModel()
        
        // Allow some time for initialization
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
    
    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() async throws {
        XCTAssertEqual(viewModel.currentState, .idle)
        XCTAssertEqual(viewModel.transcribedText, "")
        XCTAssertEqual(viewModel.processedText, "")
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.showError)
    }
    
    func testInitialComputedProperties() async throws {
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertTrue(viewModel.canRecord)
        XCTAssertFalse(viewModel.canProcessLLM)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.currentText, "")
    }
    
    // MARK: - State Transition Tests
    
    func testCompleteTranscriptionFlow() async throws {
        // Start with idle state
        XCTAssertEqual(viewModel.currentState, .idle)
        
        // Complete transcription
        let testText = "Hello, this is a test transcription"
        viewModel.completeTranscription(text: testText)
        
        XCTAssertEqual(viewModel.currentState, .transcribed)
        XCTAssertEqual(viewModel.transcribedText, testText)
        XCTAssertEqual(viewModel.currentText, testText)
        XCTAssertTrue(viewModel.canProcessLLM)
    }
    
    func testLLMProcessingFlow() async throws {
        // Setup transcribed state
        let testText = "Test transcription"
        viewModel.completeTranscription(text: testText)
        XCTAssertEqual(viewModel.currentState, .transcribed)
        
        // Start LLM processing
        viewModel.startLLMProcessing()
        XCTAssertEqual(viewModel.currentState, .processingLLM)
        XCTAssertFalse(viewModel.canRecord)
        XCTAssertTrue(viewModel.isLoading)
        
        // Wait for completion (3 second simulation)
        try await Task.sleep(nanoseconds: 3_500_000_000) // 3.5 seconds
        
        XCTAssertEqual(viewModel.currentState, .processed)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.processedText.contains("Enhanced:"))
    }
    
    func testTranscriptionStateFlow() async throws {
        viewModel.startTranscription()
        XCTAssertEqual(viewModel.currentState, .transcribing)
        XCTAssertTrue(viewModel.isLoading)
        XCTAssertFalse(viewModel.canRecord)
        
        let testText = "Transcribed content"
        viewModel.completeTranscription(text: testText)
        XCTAssertEqual(viewModel.currentState, .transcribed)
        XCTAssertEqual(viewModel.transcribedText, testText)
    }
    
    // MARK: - Current Text Logic Tests
    
    func testCurrentTextInDifferentStates() async throws {
        // Idle state
        XCTAssertEqual(viewModel.currentText, "")
        
        // Transcribed state
        let transcriptionText = "Test transcription"
        viewModel.completeTranscription(text: transcriptionText)
        XCTAssertEqual(viewModel.currentText, transcriptionText)
        
        // Processed state
        let processedText = "Enhanced content"
        viewModel.completeLLMProcessing(text: processedText)
        XCTAssertEqual(viewModel.currentText, processedText)
    }
    
    // MARK: - Reset Functionality Tests
    
    func testResetFunctionality() async throws {
        // Setup some state
        viewModel.completeTranscription(text: "Test")
        viewModel.startLLMProcessing()
        
        // Reset
        viewModel.reset()
        
        XCTAssertEqual(viewModel.currentState, .idle)
        XCTAssertEqual(viewModel.transcribedText, "")
        XCTAssertEqual(viewModel.processedText, "")
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.showError)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() async throws {
        let testError = NSError(domain: "TestError", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        viewModel.handleError(testError)
        
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.showError)
        XCTAssertEqual(viewModel.error?.localizedDescription, "Test error")
    }
    
    func testErrorRecoveryFromRecordingState() async throws {
        // Simulate recording state
        viewModel.startTranscription() // This sets state to transcribing
        // Manually set to recording for test
        viewModel.currentState = .recording
        
        let testError = NSError(domain: "TestError", code: 456)
        viewModel.handleError(testError)
        
        XCTAssertEqual(viewModel.currentState, .idle)
        XCTAssertTrue(viewModel.showError)
    }
    
    // MARK: - UI Property Tests
    
    func testPlaceholderText() async throws {
        XCTAssertEqual(viewModel.placeholderText, "Tap the record button to get started")
        
        viewModel.currentState = .recording
        XCTAssertEqual(viewModel.placeholderText, "Recording... Tap stop when finished")
        
        viewModel.currentState = .transcribing
        XCTAssertEqual(viewModel.placeholderText, "Transcribing audio...")
        
        viewModel.currentState = .transcribed
        XCTAssertEqual(viewModel.placeholderText, "Transcription complete")
        
        viewModel.currentState = .processingLLM
        XCTAssertEqual(viewModel.placeholderText, "Processing with AI...")
        
        viewModel.currentState = .processed
        XCTAssertEqual(viewModel.placeholderText, "Processing complete")
    }
    
    func testLoadingMessage() async throws {
        XCTAssertEqual(viewModel.loadingMessage, "Loading...")
        
        viewModel.currentState = .transcribing
        XCTAssertEqual(viewModel.loadingMessage, "Transcribing audio...")
        
        viewModel.currentState = .processingLLM
        XCTAssertEqual(viewModel.loadingMessage, "Processing with AI...")
    }
    
    func testRecordButtonColor() async throws {
        // Test color logic (basic validation)
        let idleColor = viewModel.recordButtonColor
        
        viewModel.currentState = .recording
        let recordingColor = viewModel.recordButtonColor
        
        viewModel.currentState = .transcribing
        let transcribingColor = viewModel.recordButtonColor
        
        // These should return Color objects (we can't test exact colors, but can test they're not nil)
        XCTAssertNotNil(idleColor)
        XCTAssertNotNil(recordingColor)
        XCTAssertNotNil(transcribingColor)
    }
    
    // MARK: - Performance Tests
    
    func testStateTransitionPerformance() async throws {
        measure {
            for _ in 0..<1000 {
                viewModel.currentState = .idle
                viewModel.currentState = .recording
                viewModel.currentState = .transcribing
                viewModel.currentState = .transcribed
                viewModel.currentState = .processed
            }
        }
    }
    
    func testComputedPropertyPerformance() async throws {
        // Setup some state
        viewModel.completeTranscription(text: "Test transcription for performance testing")
        
        measure {
            for _ in 0..<10000 {
                _ = viewModel.isRecording
                _ = viewModel.canRecord
                _ = viewModel.canProcessLLM
                _ = viewModel.isLoading
                _ = viewModel.currentText
                _ = viewModel.placeholderText
            }
        }
    }
}