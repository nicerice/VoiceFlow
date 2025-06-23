//
//  RecordButton.swift
//  VoiceFlow
//
//  Created by Sebastian Reimann on 23.06.25.
//

import SwiftUI

struct RecordButton: View {
    @Binding var isRecording: Bool
    let action: () -> Void
    
    var body: some View {
        ButtonComponent(
            icon: isRecording ? "stop.circle.fill" : "circle.fill",
            action: action,
            color: .red
        )
        .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
        .accessibilityHint(isRecording ? "Stop recording audio" : "Start recording audio")
    }
}