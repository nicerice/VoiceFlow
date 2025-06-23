//
//  AppStateTests.swift
//  VoiceFlowTests
//
//  Created by Sebastian Reimann on 23.06.25.
//

import XCTest
@testable import VoiceFlow

@MainActor
final class AppStateTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    func testIdleState() throws {
        let state = AppState.idle
        
        XCTAssertFalse(state.isLoading)
        XCTAssertTrue(state.canRecord)
        XCTAssertFalse(state.isRecording)
        XCTAssertFalse(state.canProcessLLM)
    }
    
    func testRecordingState() throws {
        let state = AppState.recording
        
        XCTAssertFalse(state.isLoading)
        XCTAssertTrue(state.canRecord) // Critical: Should still allow stopping
        XCTAssertTrue(state.isRecording)
        XCTAssertFalse(state.canProcessLLM)
    }
    
    func testTranscribingState() throws {
        let state = AppState.transcribing
        
        XCTAssertTrue(state.isLoading)
        XCTAssertFalse(state.canRecord)
        XCTAssertFalse(state.isRecording)
        XCTAssertFalse(state.canProcessLLM)
    }
    
    func testTranscribedState() throws {
        let state = AppState.transcribed
        
        XCTAssertFalse(state.isLoading)
        XCTAssertTrue(state.canRecord)
        XCTAssertFalse(state.isRecording)
        XCTAssertTrue(state.canProcessLLM)
    }
    
    func testProcessingLLMState() throws {
        let state = AppState.processingLLM
        
        XCTAssertTrue(state.isLoading)
        XCTAssertFalse(state.canRecord)
        XCTAssertFalse(state.isRecording)
        XCTAssertFalse(state.canProcessLLM)
    }
    
    func testProcessedState() throws {
        let state = AppState.processed
        
        XCTAssertFalse(state.isLoading)
        XCTAssertTrue(state.canRecord)
        XCTAssertFalse(state.isRecording)
        XCTAssertFalse(state.canProcessLLM)
    }
    
    // Note: There is no error state in the actual AppState enum
    // The error handling is done in the ViewModel through the handleError method
    
    func testCanRecordProperty() throws {
        // Can record states
        XCTAssertTrue(AppState.idle.canRecord)
        XCTAssertTrue(AppState.recording.canRecord) // Critical fix for stop button
        XCTAssertTrue(AppState.transcribed.canRecord)
        XCTAssertTrue(AppState.processed.canRecord)
        
        // Cannot record states
        XCTAssertFalse(AppState.transcribing.canRecord)
        XCTAssertFalse(AppState.processingLLM.canRecord)
    }
    
    func testIsLoadingProperty() throws {
        // Loading states
        XCTAssertTrue(AppState.transcribing.isLoading)
        XCTAssertTrue(AppState.processingLLM.isLoading)
        
        // Non-loading states
        XCTAssertFalse(AppState.idle.isLoading)
        XCTAssertFalse(AppState.recording.isLoading)
        XCTAssertFalse(AppState.transcribed.isLoading)
        XCTAssertFalse(AppState.processed.isLoading)
    }
    
    func testIsRecordingProperty() throws {
        // Recording state
        XCTAssertTrue(AppState.recording.isRecording)
        
        // Non-recording states
        XCTAssertFalse(AppState.idle.isRecording)
        XCTAssertFalse(AppState.transcribing.isRecording)
        XCTAssertFalse(AppState.transcribed.isRecording)
        XCTAssertFalse(AppState.processingLLM.isRecording)
        XCTAssertFalse(AppState.processed.isRecording)
    }
    
    func testCanProcessLLMProperty() throws {
        // Can process LLM
        XCTAssertTrue(AppState.transcribed.canProcessLLM)
        XCTAssertTrue(AppState.processed.canProcessLLM)
        
        // Cannot process LLM
        XCTAssertFalse(AppState.idle.canProcessLLM)
        XCTAssertFalse(AppState.recording.canProcessLLM)
        XCTAssertFalse(AppState.transcribing.canProcessLLM)
        XCTAssertFalse(AppState.processingLLM.canProcessLLM)
    }
    
    func testStateTransitionLogic() throws {
        // Test that state properties are consistent
        for state in [AppState.idle, .recording, .transcribing, .transcribed, .processingLLM, .processed] {
            // If isRecording is true, canRecord should also be true (for stop button)
            if state.isRecording {
                XCTAssertTrue(state.canRecord, "State \(state) should allow recording when isRecording is true")
            }
            
            // If isLoading is true, canProcessLLM should be false
            if state.isLoading {
                XCTAssertFalse(state.canProcessLLM, "State \(state) should not allow LLM processing when loading")
            }
        }
    }
}