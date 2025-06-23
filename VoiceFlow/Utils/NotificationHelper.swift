//
//  NotificationHelper.swift
//  VoiceFlow
//
//  Created by Sebastian Reimann on 23.06.25.
//

import Foundation
import UserNotifications

class NotificationHelper {
    static let shared = NotificationHelper()
    
    private init() {}
    
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound]
            )
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }
    
    func showErrorNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Show immediately
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to show notification: \(error)")
            }
        }
    }
    
    func showPermissionDeniedNotification() {
        showErrorNotification(
            title: "Microphone Permission Required",
            message: "Voice Flow needs microphone access to record audio. Please grant permission in System Preferences > Privacy & Security > Microphone."
        )
    }
    
    func showRecordingErrorNotification() {
        showErrorNotification(
            title: "Recording Error",
            message: "Failed to start recording. Please check your microphone connection and try again."
        )
    }
    
    func showTranscriptionErrorNotification() {
        showErrorNotification(
            title: "Transcription Error",
            message: "Failed to transcribe audio. Please try recording again."
        )
    }
}