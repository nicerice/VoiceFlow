//
//  MagicWandButton.swift
//  VoiceFlow
//
//  Created by Sebastian Reimann on 23.06.25.
//

import SwiftUI

struct MagicWandButton: View {
    let action: () -> Void
    let isEnabled: Bool
    let isProcessing: Bool
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    
    init(action: @escaping () -> Void, isEnabled: Bool, isProcessing: Bool = false) {
        self.action = action
        self.isEnabled = isEnabled
        self.isProcessing = isProcessing
    }
    
    var body: some View {
        ButtonComponent(
            icon: "wand.and.rays",
            action: action,
            isEnabled: isEnabled,
            color: isProcessing ? .purple : nil
        )
        .scaleEffect(pulseScale)
        .rotationEffect(.degrees(rotationAngle))
        .onAppear {
            startAnimationIfProcessing()
        }
        .onChange(of: isProcessing) { newValue in
            if newValue {
                startProcessingAnimation()
            } else {
                stopProcessingAnimation()
            }
        }
        .accessibilityLabel("Magic wand")
        .accessibilityHint("Process the transcribed text with AI")
    }
    
    private func startAnimationIfProcessing() {
        if isProcessing {
            startProcessingAnimation()
        }
    }
    
    private func startProcessingAnimation() {
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
    
    private func stopProcessingAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            pulseScale = 1.0
            rotationAngle = 0
        }
    }
}