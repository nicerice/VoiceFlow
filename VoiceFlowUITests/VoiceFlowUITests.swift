//
//  VoiceFlowUITests.swift
//  VoiceFlowUITests
//
//  Created by Sebastian Reimann on 23.06.25.
//

import XCTest

/// Comprehensive UI tests for VoiceFlow app to ensure excellent user experience
final class VoiceFlowUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Reset app state for consistent testing
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - App Launch and Basic UI Tests

    @MainActor
    func testAppLaunchesSuccessfully() throws {
        // Test that app launches without crashing
        XCTAssertTrue(app.windows.firstMatch.exists, "App window should exist")
        
        // Test main title is visible
        let titleText = app.staticTexts["VOICE FLOW"]
        XCTAssertTrue(titleText.waitForExistence(timeout: 5), "Main title should be visible")
    }
    
    @MainActor
    func testInitialUIState() throws {
        // Test initial state elements
        let promptLabel = app.staticTexts["YOUR PROMPT"]
        XCTAssertTrue(promptLabel.exists, "Prompt label should exist")
        
        let placeholderText = app.staticTexts["Tap the record button to get started"]
        XCTAssertTrue(placeholderText.waitForExistence(timeout: 3), "Initial placeholder should be visible")
        
        // Test that all main buttons are present and accessible
        let buttons = app.buttons
        XCTAssertTrue(buttons.count >= 3, "Should have at least 3 main buttons")
    }
    
    // MARK: - Recording Workflow Tests
    
    @MainActor
    func testRecordButtonInteraction() throws {
        // Find record button by looking for red circular button
        let recordButton = app.buttons.element(boundBy: 1) // Middle button in the row
        XCTAssertTrue(recordButton.waitForExistence(timeout: 5), "Record button should exist")
        
        // Test button is initially enabled
        XCTAssertTrue(recordButton.isEnabled, "Record button should be enabled initially")
        
        // Tap record button
        recordButton.tap()
        
        // Check that UI updates to recording state
        let recordingText = app.staticTexts["Recording... Tap stop when finished"]
        XCTAssertTrue(recordingText.waitForExistence(timeout: 3), "Recording placeholder should appear")
        
        // Verify button is still enabled (critical fix test)
        XCTAssertTrue(recordButton.isEnabled, "Record button should remain enabled during recording")
        
        // Stop recording
        recordButton.tap()
        
        // Should transition to transcribing state
        let transcribingText = app.staticTexts["Transcribing audio..."]
        XCTAssertTrue(transcribingText.waitForExistence(timeout: 3), "Transcribing message should appear")
    }
    
    @MainActor
    func testCompleteRecordingWorkflow() throws {
        let recordButton = app.buttons.element(boundBy: 1) // Middle button
        
        // Start recording
        recordButton.tap()
        
        // Wait a moment to simulate recording
        Thread.sleep(forTimeInterval: 2.0)
        
        // Stop recording
        recordButton.tap()
        
        // Wait for transcription to complete
        let transcriptionComplete = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'transcription' OR label CONTAINS 'simulation' OR label CONTAINS 'clear speech'"))
        XCTAssertTrue(transcriptionComplete.firstMatch.waitForExistence(timeout: 15), "Transcription should complete")
    }
    
    // MARK: - Button State Tests
    
    @MainActor
    func testCopyButtonState() throws {
        let copyButton = app.buttons.element(boundBy: 0) // First button (copy)
        
        // Initially should be disabled (no text to copy)
        XCTAssertFalse(copyButton.isEnabled, "Copy button should be disabled initially")
        
        // After transcription, should be enabled
        performQuickRecording()
        
        // Wait for transcription
        Thread.sleep(forTimeInterval: 8.0)
        
        // Copy button should now be enabled if there's text
        if app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'transcription' OR label CONTAINS 'simulation'")).firstMatch.exists {
            XCTAssertTrue(copyButton.isEnabled, "Copy button should be enabled after transcription")
        }
    }
    
    @MainActor
    func testMagicWandButtonWorkflow() throws {
        // Complete a recording first
        performQuickRecording()
        
        // Wait for transcription
        Thread.sleep(forTimeInterval: 8.0)
        
        let magicWandButton = app.buttons.element(boundBy: 2) // Third button (magic wand)
        XCTAssertTrue(magicWandButton.exists, "Magic wand button should exist")
        
        if magicWandButton.isEnabled {
            magicWandButton.tap()
            
            // Should show LLM processing state
            let processingText = app.staticTexts["Processing with AI..."]
            XCTAssertTrue(processingText.waitForExistence(timeout: 3), "LLM processing message should appear")
        }
    }
    
    // MARK: - Debug Mode Tests (Development Build Only)
    
    @MainActor
    func testDebugModeButtons() throws {
        // In debug builds, there should be helper buttons
        let sampleTextButton = app.buttons["Sample Text"]
        let resetButton = app.buttons["Reset"]
        
        if sampleTextButton.exists {
            sampleTextButton.tap()
            
            // Should populate with sample text
            let sampleText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'sample'"))
            XCTAssertTrue(sampleText.firstMatch.waitForExistence(timeout: 2), "Sample text should appear")
        }
        
        if resetButton.exists {
            resetButton.tap()
            
            // Should return to initial state
            let initialPlaceholder = app.staticTexts["Tap the record button to get started"]
            XCTAssertTrue(initialPlaceholder.waitForExistence(timeout: 2), "Should return to initial state")
        }
    }
    
    // MARK: - Error Handling UI Tests
    
    @MainActor
    func testErrorDialogHandling() throws {
        // Perform actions that might trigger errors
        let recordButton = app.buttons.element(boundBy: 1)
        
        // Rapid start/stop to potentially trigger error
        for _ in 0..<3 {
            recordButton.tap()
            Thread.sleep(forTimeInterval: 0.1)
            recordButton.tap()
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        // Check if error alert appears
        let errorAlert = app.alerts["Error"]
        if errorAlert.waitForExistence(timeout: 3) {
            let okButton = errorAlert.buttons["OK"]
            XCTAssertTrue(okButton.exists, "Error alert should have OK button")
            okButton.tap()
        }
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testUIResponsiveness() throws {
        let recordButton = app.buttons.element(boundBy: 1)
        
        // Measure button response time
        let startTime = CFAbsoluteTimeGetCurrent()
        recordButton.tap()
        
        // UI should update quickly
        let recordingText = app.staticTexts["Recording... Tap stop when finished"]
        XCTAssertTrue(recordingText.waitForExistence(timeout: 1), "UI should update within 1 second")
        
        let responseTime = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(responseTime, 0.5, "UI should respond within 0.5 seconds")
    }
    
    @MainActor
    func testAppLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let testApp = XCUIApplication()
            testApp.launch()
            testApp.terminate()
        }
    }
    
    // MARK: - Visual Layout Tests
    
    @MainActor
    func testUILayout() throws {
        // Test that main UI elements are properly positioned
        let titleText = app.staticTexts["VOICE FLOW"]
        let promptLabel = app.staticTexts["YOUR PROMPT"]
        let recordButton = app.buttons.element(boundBy: 1)
        
        XCTAssertTrue(titleText.exists, "Title should be visible")
        XCTAssertTrue(promptLabel.exists, "Prompt label should be visible")
        XCTAssertTrue(recordButton.exists, "Record button should be visible")
        
        // Test relative positioning (title should be above prompt, etc.)
        let titleFrame = titleText.frame
        let promptFrame = promptLabel.frame
        
        XCTAssertLessThan(titleFrame.midY, promptFrame.midY, "Title should be above prompt")
    }
    
    // MARK: - Integration Tests
    
    @MainActor
    func testMicrophonePermissionFlow() throws {
        let recordButton = app.buttons.element(boundBy: 1)
        recordButton.tap()
        
        // Wait for either recording to start or error to appear
        let recordingStarted = app.staticTexts["Recording... Tap stop when finished"]
        let errorAlert = app.alerts["Error"]
        
        let recordingExists = recordingStarted.waitForExistence(timeout: 5)
        let errorExists = errorAlert.waitForExistence(timeout: 2)
        
        // One of these should happen
        XCTAssertTrue(recordingExists || errorExists, "Should either start recording or show permission error")
        
        if errorExists {
            errorAlert.buttons["OK"].tap()
        }
    }
    
    // MARK: - State Consistency Tests
    
    @MainActor
    func testStateConsistency() throws {
        let recordButton = app.buttons.element(boundBy: 1)
        let copyButton = app.buttons.element(boundBy: 0)
        let magicWandButton = app.buttons.element(boundBy: 2)
        
        // Initial state - copy and magic wand should be disabled
        XCTAssertFalse(copyButton.isEnabled, "Copy button should be disabled initially")
        XCTAssertFalse(magicWandButton.isEnabled, "Magic wand should be disabled initially")
        XCTAssertTrue(recordButton.isEnabled, "Record button should be enabled initially")
        
        // During recording - record button should stay enabled (critical test)
        recordButton.tap()
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertTrue(recordButton.isEnabled, "Record button should remain enabled during recording")
    }
    
    // MARK: - Edge Case Tests
    
    @MainActor
    func testVeryShortRecording() throws {
        let recordButton = app.buttons.element(boundBy: 1)
        
        // Very short recording
        recordButton.tap()
        Thread.sleep(forTimeInterval: 0.2)
        recordButton.tap()
        
        // Should handle gracefully
        let transcribingOrError = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Transcribing' OR label CONTAINS 'short' OR label CONTAINS 'empty'"))
        XCTAssertTrue(transcribingOrError.firstMatch.waitForExistence(timeout: 5), "Should handle short recording gracefully")
    }
    
    // MARK: - Helper Methods
    
    private func performQuickRecording() {
        let recordButton = app.buttons.element(boundBy: 1)
        recordButton.tap()
        Thread.sleep(forTimeInterval: 2.0) // 2 second recording
        recordButton.tap()
    }
}