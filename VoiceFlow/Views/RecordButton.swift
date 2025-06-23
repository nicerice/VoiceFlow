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
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ButtonComponent(
            icon: isRecording ? "stop.circle.fill" : "circle.fill",
            action: action,
            color: .red
        )
        .scaleEffect(pulseScale)
        .onAppear {
            startPulsingIfRecording()
        }
        .onChange(of: isRecording) { newValue in
            if newValue {
                startPulsing()
            } else {
                stopPulsing()
            }
        }
        .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
        .accessibilityHint(isRecording ? "Stop recording audio" : "Start recording audio")
    }
    
    private func startPulsingIfRecording() {
        if isRecording {
            startPulsing()
        }
    }
    
    private func startPulsing() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
        }
    }
    
    private func stopPulsing() {
        withAnimation(.easeInOut(duration: 0.2)) {
            pulseScale = 1.0
        }
    }
}