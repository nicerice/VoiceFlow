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
    
    var body: some View {
        ButtonComponent(
            icon: "wand.and.rays",
            action: action,
            isEnabled: isEnabled
        )
        .accessibilityLabel("Magic wand")
        .accessibilityHint("Process the transcribed text with AI")
    }
}