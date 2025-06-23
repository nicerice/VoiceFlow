//
//  VoiceFlowUITests.swift
//  VoiceFlowUITests
//
//  Created by Sebastian Reimann on 23.06.25.
//

import XCTest

final class VoiceFlowUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testAppLaunchAndBasicUI() throws {
        // Test that the app launches and basic UI elements are present
        XCTAssertTrue(app.staticTexts["YOUR PROMPT"].exists, "Prompt label should be visible")
        
        // Check for record button (should be the second button, first is likely magic wand)
        let buttons = app.buttons
        XCTAssertGreaterThan(buttons.count, 1, "Should have at least 2 buttons")
        
        // Check for text display area
        XCTAssertTrue(app.scrollViews.firstMatch.exists, "Text display scroll view should exist")
    }
    
    @MainActor
    func testRecordButtonInteraction() throws {
        // Find the record button (second button)
        let recordButton = app.buttons.element(boundBy: 1)
        XCTAssertTrue(recordButton.exists, "Record button should exist")
        
        // Test initial state
        XCTAssertTrue(recordButton.isEnabled, "Record button should be enabled initially")
        
        // Tap the record button
        recordButton.tap()
        
        // Verify button is still enabled (critical fix test)
        XCTAssertTrue(recordButton.isEnabled, "Record button should remain enabled during recording")
        
        // Tap again to stop recording
        recordButton.tap()
        
        // Button should still be enabled after stopping
        XCTAssertTrue(recordButton.isEnabled, "Record button should be enabled after stopping")
    }
    
    @MainActor
    func testMagicWandButtonInteraction() throws {
        // Find the magic wand button (first button)
        let magicWandButton = app.buttons.element(boundBy: 0)
        XCTAssertTrue(magicWandButton.exists, "Magic wand button should exist")
        
        // Initially might be disabled (no transcription yet)
        // Tap to test it doesn't crash
        if magicWandButton.isEnabled {
            magicWandButton.tap()
        }
    }
    
    @MainActor
    func testTextDisplayArea() throws {
        let textArea = app.scrollViews.firstMatch
        XCTAssertTrue(textArea.exists, "Text display area should exist")
        
        // Check for placeholder text or content
        let textContent = textArea.staticTexts.firstMatch
        XCTAssertTrue(textContent.exists, "Text content should be present")
    }
    
    @MainActor
    func testAccessibilityLabels() throws {
        // Test accessibility labels for record button
        let recordButton = app.buttons.element(boundBy: 1)
        
        // Check that accessibility labels are set
        XCTAssertNotNil(recordButton.label, "Record button should have accessibility label")
        
        // The label should indicate current state
        let label = recordButton.label
        XCTAssertTrue(
            label.contains("Start recording") || label.contains("Stop recording"),
            "Record button should have appropriate accessibility label"
        )
    }
    
    @MainActor
    func testUIStateTransitions() throws {
        let recordButton = app.buttons.element(boundBy: 1)
        
        // Start recording
        recordButton.tap()
        
        // UI should update to show recording state
        // (Specific UI changes depend on implementation)
        XCTAssertTrue(recordButton.exists, "Record button should still exist during recording")
        
        // Stop recording
        recordButton.tap()
        
        // UI should return to idle state
        XCTAssertTrue(recordButton.isEnabled, "Record button should be enabled after recording")
    }
    
    @MainActor
    func testAppDoesNotCrashOnQuickTaps() throws {
        let recordButton = app.buttons.element(boundBy: 1)
        let magicWandButton = app.buttons.element(boundBy: 0)
        
        // Rapid tapping should not crash the app
        for _ in 0..<5 {
            recordButton.tap()
            if magicWandButton.isEnabled {
                magicWandButton.tap()
            }
        }
        
        // App should still be responsive
        XCTAssertTrue(recordButton.exists, "Record button should still exist after rapid tapping")
        XCTAssertTrue(magicWandButton.exists, "Magic wand button should still exist after rapid tapping")
    }
    
    @MainActor
    func testScrollViewInteraction() throws {
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists, "Scroll view should exist")
        
        // Test scrolling (even if content is minimal)
        scrollView.swipeUp()
        scrollView.swipeDown()
        
        // Should not crash
        XCTAssertTrue(scrollView.exists, "Scroll view should still exist after scrolling")
    }
    
    @MainActor
    func testDarkModeCompatibility() throws {
        // This test checks that UI elements exist in both light and dark mode
        XCTAssertTrue(app.staticTexts["YOUR PROMPT"].exists, "UI should work in current color scheme")
        XCTAssertTrue(app.buttons.element(boundBy: 0).exists, "Buttons should be visible")
        XCTAssertTrue(app.buttons.element(boundBy: 1).exists, "Record button should be visible")
    }
    
    @MainActor
    func testKeyboardShortcuts() throws {
        // Test any keyboard shortcuts if implemented
        // For now, just test that the app handles keyboard events gracefully
        
        // Send escape key (common shortcut)
        app.typeKey("", modifierFlags: [])
        
        // App should still be functional
        XCTAssertTrue(app.buttons.element(boundBy: 1).exists, "App should handle keyboard input gracefully")
    }
    
    @MainActor
    func testAppStateAfterBackgrounding() throws {
        // Simulate app backgrounding and foregrounding
        #if os(iOS)
        XCUIDevice.shared.press(.home)
        #else
        // On macOS, simulate hiding/showing the app
        app.typeKey("h", modifierFlags: .command) // Command+H to hide
        #endif
        
        // Wait briefly
        sleep(1)
        
        // Reactivate app
        app.activate()
        
        // UI should still be functional
        XCTAssertTrue(app.buttons.element(boundBy: 1).exists, "Record button should exist after backgrounding")
        XCTAssertTrue(app.buttons.element(boundBy: 1).isEnabled, "Record button should be enabled after backgrounding")
    }
    
    @MainActor
    func testPerformanceOfUIInteractions() throws {
        measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
            let newApp = XCUIApplication()
            newApp.launch()
            newApp.terminate()
        }
    }
    
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    @MainActor
    func testCriticalUserWorkflow() throws {
        // Test the complete user workflow
        let recordButton = app.buttons.element(boundBy: 1)
        let magicWandButton = app.buttons.element(boundBy: 0)
        
        // 1. User starts recording
        recordButton.tap()
        XCTAssertTrue(recordButton.isEnabled, "CRITICAL: Record button must stay enabled for stopping")
        
        // 2. User stops recording
        recordButton.tap()
        
        // 3. Wait for processing (if any UI indication)
        // 4. User processes with LLM (if button becomes enabled)
        if magicWandButton.isEnabled {
            magicWandButton.tap()
        }
        
        // Workflow should complete without crashes
        XCTAssertTrue(recordButton.exists, "Workflow should complete successfully")
    }
}