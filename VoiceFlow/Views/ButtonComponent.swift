//
//  ButtonComponent.swift
//  VoiceFlow
//
//  Created by Sebastian Reimann on 23.06.25.
//

import SwiftUI

struct ButtonComponent: View {
    let icon: String
    let action: () -> Void
    let isEnabled: Bool
    let color: Color?
    
    @State private var isPressed = false
    @State private var isHovered = false
    @Environment(\.colorScheme) var colorScheme
    
    init(icon: String, 
         action: @escaping () -> Void, 
         isEnabled: Bool = true, 
         color: Color? = nil) {
        self.icon = icon
        self.action = action
        self.isEnabled = isEnabled
        self.color = color
    }
    
    var body: some View {
        Button(action: {
            if isEnabled {
                action()
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(foregroundColor)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(backgroundColor)
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
        .onHover { hovering in
            isHovered = hovering
        }
        .pressEvents(onPress: {
            isPressed = true
        }, onRelease: {
            isPressed = false
        })
    }
    
    private var iconSize: CGFloat {
        // Special sizing for record button
        if icon == "circle.fill" || icon == "circle" {
            return 40
        }
        return 20
    }
    
    private var foregroundColor: Color {
        if let customColor = color {
            return customColor
        }
        return isEnabled ? .primary : .secondary
    }
    
    private var backgroundColor: Color {
        if icon == "circle.fill" || icon == "circle" {
            return .clear
        }
        
        let baseOpacity = colorScheme == .dark ? 0.1 : 0.1
        let hoverOpacity = colorScheme == .dark ? 0.15 : 0.15
        
        return isHovered && isEnabled 
            ? Color.gray.opacity(hoverOpacity)
            : Color.gray.opacity(baseOpacity)
    }
}

// Extension to handle press events
extension View {
    func pressEvents(onPress: @escaping () -> Void, 
                    onRelease: @escaping () -> Void) -> some View {
        self.onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) {
            onPress()
        } onPressingChanged: { pressing in
            if !pressing {
                onRelease()
            }
        }
    }
}