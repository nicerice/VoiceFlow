//
//  VoiceFlowApp.swift
//  VoiceFlow
//
//  Created by Sebastian Reimann on 23.06.25.
//

import SwiftUI

@main
struct VoiceFlowApp: App {
    var body: some Scene {
        WindowGroup("Voice Flow") {
            ContentView()
                .frame(width: 400, height: 530)
                .onAppear {
                    if let window = NSApplication.shared.windows.first {
                        window.level = .floating
                        window.styleMask.remove(.resizable)
                    }
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 400, height: 530)
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
