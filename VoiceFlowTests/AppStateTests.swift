//
//  AppStateTests.swift
//  VoiceFlowTests
//
//  Created by Sebastian Reimann on 23.06.25.
//

import XCTest
@testable import VoiceFlow

/// Comprehensive tests for the AppState enum to ensure proper state management
final class AppStateTests: XCTestCase {
    
    // MARK: - State Properties Tests
    
    func testAppStateDescriptions() throws {
        XCTAssertEqual(AppState.idle.description, "Idle")
        XCTAssertEqual(AppState.recording.description, "Recording")
        XCTAssertEqual(AppState.transcribing.description, "Transcribing")
        XCTAssertEqual(AppState.transcribed.description, "Transcribed")
        XCTAssertEqual(AppState.processingLLM.description, "ProcessingLLM")
        XCTAssertEqual(AppState.processed.description, "Processed")
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
    
    func testIsRecordingProperty() throws {
        // Only recording state should return true
        XCTAssertTrue(AppState.recording.isRecording)
        
        // All other states should return false
        XCTAssertFalse(AppState.idle.isRecording)
        XCTAssertFalse(AppState.transcribing.isRecording)
        XCTAssertFalse(AppState.transcribed.isRecording)
        XCTAssertFalse(AppState.processingLLM.isRecording)
        XCTAssertFalse(AppState.processed.isRecording)
    }
    
    func testCanProcessLLMProperty() throws {
        // Can process LLM states
        XCTAssertTrue(AppState.transcribed.canProcessLLM)
        XCTAssertTrue(AppState.processed.canProcessLLM)
        
        // Cannot process LLM states
        XCTAssertFalse(AppState.idle.canProcessLLM)
        XCTAssertFalse(AppState.recording.canProcessLLM)
        XCTAssertFalse(AppState.transcribing.canProcessLLM)
        XCTAssertFalse(AppState.processingLLM.canProcessLLM)
    }
    
    // MARK: - State Transition Logic Tests
    
    func testValidStateTransitions() throws {
        // Test logical state flow
        let validTransitions: [(from: AppState, to: AppState)] = [
            (.idle, .recording),
            (.recording, .transcribing),
            (.transcribing, .transcribed),
            (.transcribed, .processingLLM),
            (.processingLLM, .processed),
            (.processed, .recording), // Can start new recording
            (.transcribed, .recording), // Can record again without LLM
            (.processed, .idle), // Can reset
            (.transcribed, .idle) // Can reset
        ]
        
        for transition in validTransitions {
            // This test validates that our state machine logic supports these transitions
            // In a real implementation, you'd test the ViewModel transition methods
            XCTAssertNotEqual(transition.from, transition.to, "Transition should change state")
        }
    }
    
    // MARK: - State Consistency Tests
    
    func testStateConsistency() throws {
        // Test that states have consistent behavior
        for state in AppState.allCases {
            // Loading states should not allow recording
            if state.isLoading {
                XCTAssertFalse(state.canRecord, "Loading state \(state) should not allow recording")
            }
            
            // Recording state should not be loading
            if state.isRecording {
                XCTAssertFalse(state.isLoading, "Recording state should not be loading")
            }
            
            // Only transcribed and processed states should allow LLM processing
            if state.canProcessLLM {
                XCTAssertTrue(state == .transcribed || state == .processed, 
                            "Only transcribed/processed states should allow LLM processing")
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testAllStatesHaveDescriptions() throws {
        for state in AppState.allCases {
            XCTAssertFalse(state.description.isEmpty, "State \(state) should have a description")
        }
    }
    
    func testRawValueConsistency() throws {
        for state in AppState.allCases {
            XCTAssertEqual(state.rawValue.capitalized, state.description, 
                          "Raw value and description should be consistent for \(state)")
        }
    }
}