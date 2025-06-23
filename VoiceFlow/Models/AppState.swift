//
//  AppState.swift
//  VoiceFlow
//
//  Created by Sebastian Reimann on 23.06.25.
//

import Foundation

enum AppState: String, CaseIterable, CustomStringConvertible {
    case idle = "idle"
    case recording = "recording"
    case transcribing = "transcribing"
    case transcribed = "transcribed"
    case processingLLM = "processingLLM"
    case processed = "processed"
    
    var description: String {
        return rawValue.capitalized
    }
    
    var isLoading: Bool {
        switch self {
        case .transcribing, .processingLLM:
            return true
        case .idle, .recording, .transcribed, .processed:
            return false
        }
    }
    
    var canRecord: Bool {
        switch self {
        case .idle, .transcribed, .processed:
            return true
        case .recording, .transcribing, .processingLLM:
            return false
        }
    }
    
    var isRecording: Bool {
        return self == .recording
    }
    
    var canProcessLLM: Bool {
        switch self {
        case .transcribed, .processed:
            return true
        case .idle, .recording, .transcribing, .processingLLM:
            return false
        }
    }
}