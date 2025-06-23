# Voice Flow - macOS App Specification

## Overview
Voice Flow is a macOS app that performs speech-to-text transcription using WhisperKit and offers LLM-powered text cleanup via OpenAI's GPT-4o.

## Quick Start for Developers

### Prerequisites
- Xcode 15.0+
- macOS 13.0+ development machine
- OpenAI API key
- Git LFS (for model files)

### Initial Setup
1. Clone repository: `git clone [repo-url]`
2. Download Whisper large-v3 model from Hugging Face
3. Create `Constants.swift` from template (don't commit!)
4. Add OpenAI API key to Constants.swift
5. Open `VoiceFlow.xcodeproj`
6. Build and run

## Technical Stack
- **Platform**: macOS (native app)
- **Language**: Swift
- **Speech Recognition**: WhisperKit (https://github.com/argmaxinc/WhisperKit)
- **Model**: Whisper large-v3 (pre-bundled with app)
- **LLM**: OpenAI GPT-4o
- **Distribution**: Personal/internal use only

## User Interface

### Window Properties
- **Size**: 400x530 pixels (fixed, non-resizable)
- **Behavior**: Floats above other windows
- **Menu Bar**: Standard macOS menu bar (no custom menu items for MVP)
- **Title**: "Voice Flow"

### Layout Components

1. **Title Bar**
   - Text: "VOICE FLOW"
   - Standard macOS window controls

2. **Text Display Area**
   - Label: "YOUR PROMPT"
   - Scrollable text view
   - Non-editable by user
   - Default placeholder text: "Tap the record button to get started"
   - Loading overlay appears here during processing

3. **Button Row** (bottom of window)
   - **Copy Button** (left)
     - Icon: Copy/document icon
     - Action: Copies current text to clipboard
     - Visual feedback: Quick color flash/pulse animation
     - Always visible
   
   - **Record Button** (center)
     - Default state: Circle icon
     - Recording state: Red circle with pulsing animation
     - Action: Toggle start/stop recording
     - Always enabled unless LLM is processing
   
   - **Magic Wand Button** (right)
     - Icon: Magic wand
     - Action: Send text to LLM for cleanup
     - State: Disabled when no text present
     - Visual feedback: Pulsing animation during LLM processing

## Functional Requirements

### Recording Flow
1. User clicks record button
2. Button changes to red circle with pulsing animation
3. App records audio until user clicks button again
4. Loading overlay appears in text field
5. WhisperKit transcribes audio (auto-detects language)
6. Transcribed text replaces placeholder/previous text
7. Magic wand button becomes enabled

### LLM Processing Flow
1. User clicks magic wand button (only when text exists)
2. Button shows pulsing animation
3. Loading overlay appears in text field
4. Record button is disabled
5. Text sent to GPT-4o with cleanup prompt
6. LLM response replaces original text
7. Result automatically copied to clipboard
8. All buttons return to normal state

### Loading States
- Consistent overlay design for both transcription and LLM processing
- Overlay prevents text selection/copying
- Appears over the text field content

### Copy Functionality
- Copies current text field content to clipboard
- Shows color flash/pulse animation for feedback
- Works whether text is original transcription or LLM-cleaned version

## Technical Specifications

### WhisperKit Integration
- Model: large-v3
- Bundling: Pre-bundled with application (no download required)
- Language: Auto-detection (supports German, English, and others)
- No language selection UI needed

### OpenAI Integration
- Model: gpt-4o
- API Key: Hardcoded in app (ensure not committed to repository)
- Prompt: "Clean up this transcribed speech: remove filler words (um, uh, like, you know), fix grammar, eliminate repetitions and false starts, add proper punctuation and line breaks, and maintain the original meaning while making it concise and clear. Keep the same language as the input."

### Error Handling
- All errors displayed via macOS system notifications
- No error messages in UI

### State Management
- New recordings can start anytime except during LLM processing
- Starting new recording cancels ongoing transcription
- LLM processing must complete before new recording

## Development Guidelines

### Security
- OpenAI API key must not be committed to repository
- Use environment variables or secure configuration file

### Code Organization
- Follow Swift best practices
- Use SwiftUI for interface
- Implement proper async/await for API calls

### Testing Considerations
- Test with both German and English speech
- Test interrupting transcription with new recording
- Test copy functionality in all states
- Verify loading states display correctly

## Architecture

### Application Structure
```
VoiceFlow/
├── VoiceFlowApp.swift          # App entry point
├── Views/
│   ├── ContentView.swift       # Main window view
│   ├── TextDisplayView.swift   # Scrollable text area
│   └── ButtonsView.swift       # Button row component
├── ViewModels/
│   └── RecordingViewModel.swift # Main business logic
├── Services/
│   ├── AudioRecorder.swift     # Audio recording logic
│   ├── TranscriptionService.swift # WhisperKit integration
│   └── LLMService.swift        # OpenAI API integration
├── Models/
│   ├── AppState.swift          # State management
│   └── TranscriptionResult.swift
├── Utils/
│   ├── Constants.swift         # API keys, prompts
│   └── NotificationHelper.swift
└── Resources/
    └── WhisperKit/
        └── large-v3/           # Pre-bundled model files

```

### Design Patterns
- **MVVM Architecture**: Clear separation of concerns
- **Combine Framework**: For reactive state management
- **Async/Await**: For all asynchronous operations
- **Dependency Injection**: For testability

## Data Handling

### Audio Recording
- **Format**: WAV or M4A (WhisperKit compatible)
- **Sample Rate**: 16kHz (Whisper standard)
- **Storage**: Temporary file in app sandbox
- **Cleanup**: Delete after transcription completes

### State Management
```swift
enum AppState {
    case idle
    case recording
    case transcribing
    case transcribed(String)
    case processingLLM
    case processed(String)
}
```

### Memory Management
- Release audio buffers immediately after transcription
- Clear previous transcriptions when starting new recording
- Limit text field to reasonable length (e.g., 50,000 characters)

## Error Handling Strategy

### Error Types
1. **Audio Errors**
   - Microphone permission denied
   - Audio session initialization failure
   - Recording interruption

2. **Transcription Errors**
   - Model loading failure
   - Transcription timeout (>60 seconds)
   - Memory pressure

3. **Network Errors**
   - OpenAI API connection failure
   - API rate limiting
   - Invalid API response

4. **System Errors**
   - Insufficient storage
   - App sandbox violations

### Error Responses
```swift
enum VoiceFlowError: LocalizedError {
    case microphonePermissionDenied
    case modelLoadingFailed
    case transcriptionFailed(String)
    case networkError(String)
    case apiKeyMissing
    
    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access required. Please enable in System Preferences."
        // ... etc
        }
    }
}
```

### Recovery Strategies
- Auto-retry for network failures (max 3 attempts)
- Graceful degradation (save transcription even if LLM fails)
- Clear error state on new recording

## Testing Plan

### Unit Tests
1. **AudioRecorder**
   - Test start/stop recording
   - Verify audio format settings
   - Mock microphone permissions

2. **TranscriptionService**
   - Mock WhisperKit responses
   - Test language auto-detection
   - Verify model loading

3. **LLMService**
   - Mock API responses
   - Test prompt formatting
   - Verify error handling

### Integration Tests
1. **Recording → Transcription Flow**
   - Record 5-second sample
   - Verify transcription completes
   - Check state transitions

2. **Transcription → LLM Flow**
   - Provide sample text
   - Verify LLM processing
   - Check clipboard update

### UI Tests
1. **Button States**
   - Record button appearance changes
   - Magic wand enable/disable logic
   - Copy button feedback

2. **Loading States**
   - Overlay appearance
   - Text field interaction blocking
   - Proper cleanup after completion

### Manual Testing Checklist
- [ ] Test with German speech (30+ seconds)
- [ ] Test with English speech (30+ seconds)
- [ ] Test code-switching (German to English mid-sentence)
- [ ] Test interrupting recording
- [ ] Test interrupting transcription
- [ ] Test very long recordings (3+ minutes)
- [ ] Test rapid button clicks
- [ ] Test with no internet (LLM should fail gracefully)
- [ ] Test window floating behavior
- [ ] Test copy functionality with Unicode text
- [ ] Test system notification appearance
- [ ] Verify no API key in repository

### Performance Benchmarks
- App launch: < 2 seconds
- Recording start: < 100ms
- Transcription: < 2x real-time
- LLM response: < 5 seconds
- Memory usage: < 500MB

## Implementation Priority

### Phase 1: Core Recording (Day 1-2)
1. Basic UI layout
2. Audio recording functionality
3. Button state management

### Phase 2: WhisperKit Integration (Day 3-4)
1. Bundle model with app
2. Implement transcription
3. Loading states

### Phase 3: LLM Integration (Day 5)
1. OpenAI API setup
2. Text processing
3. Clipboard functionality

### Phase 4: Polish & Testing (Day 6-7)
1. Animations and feedback
2. Error handling
3. Comprehensive testing

## Dependencies

### Swift Package Manager
```swift
dependencies: [
    .package(url: "https://github.com/argmaxinc/WhisperKit", from: "0.5.0")
]
```

### Info.plist Requirements
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Voice Flow needs microphone access to transcribe your speech.</string>
```

### Build Settings
- Minimum macOS version: 13.0 (Ventura)
- Swift version: 5.9+
- Architecture: Universal (Apple Silicon + Intel)

## Security Considerations

### API Key Management
```swift
// Constants.swift (add to .gitignore)
enum APIKeys {
    static let openAI = "sk-..."  // Never commit this file
}

// Alternative: Use environment variable
let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
```

### Network Security
- Use URLSession with default security settings
- Validate HTTPS certificates
- No custom certificate pinning needed for MVP

## Future Considerations (Post-MVP)
- Settings/preferences window
- Keyboard shortcuts for recording
- API key configuration UI
- Model selection options
- Export functionality
- History of transcriptions
## Implementation Notes

### Key Code Snippets

#### Recording Button State
```swift
@Published var isRecording = false
@Published var recordButtonColor: Color {
    isRecording ? .red : .primary
}

func toggleRecording() {
    withAnimation(.easeInOut(duration: 0.2)) {
        isRecording.toggle()
    }
    
    if isRecording {
        startRecording()
    } else {
        stopRecording()
    }
}
```

#### Pulsing Animation
```swift
struct PulsingView: ViewModifier {
    @State private var animating = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(animating ? 1.1 : 1.0)
            .opacity(animating ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animating)
            .onAppear { animating = true }
    }
}
```

#### Loading Overlay
```swift
struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
        }
        .allowsHitTesting(true) // Blocks interaction
    }
}
```

#### OpenAI API Call
```swift
func cleanupText(_ text: String) async throws -> String {
    let messages = [
        ["role": "user", "content": Constants.llmPrompt + "\n\n" + text]
    ]
    
    let requestBody: [String: Any] = [
        "model": "gpt-4o",
        "messages": messages,
        "temperature": 0.3,
        "max_tokens": 2000
    ]
    
    // API call implementation...
}
```

### Common Pitfalls to Avoid
1. Don't forget to request microphone permissions before first recording
2. WhisperKit needs to run on main thread for UI updates
3. Always clean up temporary audio files
4. Handle the case where clipboard access might fail
5. Test with actual speech, not just UI interactions

### Debugging Tips
- Enable WhisperKit verbose logging for model loading issues
- Use Console.app to view system notifications
- Test with different audio input devices
- Monitor memory usage during long recordings

## Final Developer Checklist
- [ ] Set up development environment
- [ ] Implement core UI with SwiftUI
- [ ] Integrate WhisperKit with bundled model
- [ ] Add audio recording functionality
- [ ] Implement state management
- [ ] Add OpenAI integration
- [ ] Implement all animations and feedback
- [ ] Add error handling and notifications
- [ ] Test all user flows
- [ ] Ensure API key is not in repository
- [ ] Create .gitignore for sensitive files
- [ ] Document any deviations from spec

This specification is complete and ready for implementation. The developer should have everything needed to build Voice Flow from scratch.