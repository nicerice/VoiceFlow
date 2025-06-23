//
//  CopyButton.swift
//  VoiceFlow
//
//  Created by Sebastian Reimann on 23.06.25.
//

import SwiftUI

struct CopyButton: View {
    let action: () -> Void
    let isEnabled: Bool
    @State private var showCopied = false
    
    var body: some View {
        ButtonComponent(
            icon: showCopied ? "checkmark" : "doc.on.doc",
            action: {
                action()
                showCopyFeedback()
            },
            isEnabled: isEnabled,
            color: showCopied ? .green : nil
        )
        .accessibilityLabel("Copy")
        .accessibilityHint("Copy the transcribed text to clipboard")
    }
    
    private func showCopyFeedback() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showCopied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopied = false
            }
        }
    }
}