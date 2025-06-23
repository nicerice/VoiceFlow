//
//  TextDisplayView.swift
//  VoiceFlow
//
//  Created by Sebastian Reimann on 23.06.25.
//

import SwiftUI

struct TextDisplayView: View {
    @Binding var text: String
    @Binding var isLoading: Bool
    var placeholderText: String = "Tap the record button to get started"
    var loadingMessage: String = "Loading..."
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YOUR PROMPT")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .tracking(0.5)
            
            ZStack {
                // Text display area
                ScrollView {
                    Text(text.isEmpty ? placeholderText : text)
                        .font(.system(size: 14))
                        .foregroundColor(text.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.2), lineWidth: 1)
                )
                
                // Loading overlay
                if isLoading {
                    LoadingOverlay(message: loadingMessage)
                }
            }
        }
    }
    
    func updateText(_ newText: String) {
        text = newText
    }
    
    func showLoading() {
        isLoading = true
    }
    
    func hideLoading() {
        isLoading = false
    }
}

struct LoadingOverlay: View {
    var message: String = "Loading..."
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ? Color.black.opacity(0.8) : Color.white.opacity(0.9))
            
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle())
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .allowsHitTesting(true)
    }
}