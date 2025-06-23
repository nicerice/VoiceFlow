# Voice Flow - macOS App Development Guide

## Overview
Voice Flow is a macOS app that performs speech-to-text transcription using WhisperKit and offers LLM-powered text cleanup via OpenAI's GPT-4o. This document provides comprehensive guidance for developing the application using AI assistance.

## Quick Start for Developers

### Prerequisites
- Xcode 15.0+
- macOS 13.0+ development machine
- OpenAI API key
- Git LFS (for model files)

### Development Approach
This project is designed to be built incrementally through 24 development steps, each building upon the previous ones. Each step is documented as a GitHub issue with specific implementation requirements.

## Technical Stack
- **Platform**: macOS (native app)
- **Language**: Swift
- **UI Framework**: SwiftUI
- **Architecture**: MVVM
- **Speech Recognition**: WhisperKit (https://github.com/argmaxinc/WhisperKit)
- **Model**: Whisper large-v3 (pre-bundled with app)
- **LLM**: OpenAI GPT-4o
- **Distribution**: Personal/internal use only

## Application Specifications

### Window Properties
- **Size**: 400x530 pixels (fixed, non-resizable)
- **Behavior**: Floats above other windows
- **Title**: "Voice Flow"

### Core Features
1. **Audio Recording**: Record audio using device microphone
2. **Speech Transcription**: Convert audio to text using WhisperKit
3. **LLM Processing**: Clean up transcribed text using OpenAI GPT-4o
4. **Clipboard Integration**: Copy results to clipboard
5. **Loading States**: Visual feedback during processing

### User Interface Components
1. **Title Bar**: "VOICE FLOW" text with standard macOS controls
2. **Text Display Area**: Scrollable, non-editable text view with loading overlay
3. **Button Row**: Copy, Record, and Magic Wand buttons

## Development Phases

### Phase 1: Foundation Setup (Issues #1-3)
- Project configuration and basic UI structure
- Window properties and layout components
- Interactive UI elements

### Phase 2: Interactive UI Components (Issues #4-6)
- Button component creation
- Text display component
- Basic button interactions

### Phase 3: State Management Foundation (Issues #7-9)
- State management system
- State-driven UI updates
- State transition logic

### Phase 4: Audio Recording Infrastructure (Issues #10-12)
- Audio permissions and session setup
- Audio recording service
- Recording integration with UI

### Phase 5: Speech Transcription (Issues #13-15)
- WhisperKit dependency and setup
- Transcription service implementation
- Transcription pipeline integration

### Phase 6: LLM Text Processing (Issues #16-18)
- OpenAI service implementation
- LLM processing integration
- Clipboard integration

### Phase 7: Polish and User Experience (Issues #19-21)
- Loading states and animations
- Visual feedback system
- Final UI polish

### Phase 8: Robustness and Reliability (Issues #22-24)
- Comprehensive error handling
- System notifications and integration
- Final integration and testing

## Implementation Guidelines

### Architecture Patterns
- **MVVM Architecture**: Clear separation of concerns
- **Combine Framework**: For reactive state management
- **Async/Await**: For all asynchronous operations
- **Dependency Injection**: For testability

### Code Organization
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

## Security Considerations

### API Key Management
- OpenAI API key must not be committed to repository
- Use Constants.swift template approach
- Add Constants.swift to .gitignore

### Example Constants.swift (not committed):
```swift
enum APIKeys {
    static let openAI = "sk-..."  // Never commit this file
}

enum LLMConstants {
    static let prompt = "Clean up this transcribed speech: remove filler words..."
    static let model = "gpt-4o"
    static let temperature = 0.3
    static let maxTokens = 2000
}
```

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

## Error Handling Strategy

### Error Types
1. **Audio Errors**: Microphone permission denied, recording failures
2. **Transcription Errors**: Model loading failure, transcription timeout
3. **Network Errors**: OpenAI API failures, connectivity issues
4. **System Errors**: Insufficient storage, app sandbox violations

### Error Responses
- All errors displayed via macOS system notifications
- No error messages in UI
- Graceful degradation and recovery

## Testing Strategy

### Unit Tests
- AudioRecorder functionality
- TranscriptionService integration
- LLMService API handling

### Integration Tests
- Recording → Transcription flow
- Transcription → LLM flow
- Complete end-to-end workflows

### Manual Testing Checklist
- [ ] German speech transcription (30+ seconds)
- [ ] English speech transcription (30+ seconds)
- [ ] Code-switching (German to English)
- [ ] Interrupting operations
- [ ] Very long recordings (3+ minutes)
- [ ] No internet connectivity handling
- [ ] Copy functionality with Unicode text
- [ ] Window floating behavior

## Performance Benchmarks
- App launch: < 2 seconds
- Recording start: < 100ms
- Transcription: < 2x real-time
- LLM response: < 5 seconds
- Memory usage: < 500MB

## Development Best Practices

### Code Quality
- Follow Swift best practices
- Use SwiftUI for interface
- Implement proper async/await for API calls
- Maintain consistent naming conventions

### Git Workflow
- Each issue should be implemented in a separate feature branch
- Use descriptive commit messages
- Create pull requests for code review
- Ensure all tests pass before merging

### Documentation
- Comment complex logic
- Document public interfaces
- Update README as features are added
- Maintain this CLAUDE.md file

## AI Development Tips

When working with AI assistants like Claude:

1. **Reference This Document**: Always refer to this CLAUDE.md file for context
2. **Follow Issue Order**: Implement issues in numerical order to maintain dependencies
3. **Include Context**: When asking for help, include relevant code from previous steps
4. **Test Incrementally**: Test each step before moving to the next
5. **Ask for Clarification**: If requirements are unclear, ask for specific examples

### Prompt Structure for AI Assistance
```
Building on [previous step/issue], implement [specific feature] for the Voice Flow macOS app.

Current project structure:
[include relevant files/code]

Requirements:
[specific requirements from the issue]

Please provide:
1. Complete implementation
2. Integration with existing code
3. Error handling
4. Testing considerations
```

## Common Pitfalls to Avoid

1. Don't forget to request microphone permissions before first recording
2. WhisperKit needs to run on main thread for UI updates
3. Always clean up temporary audio files
4. Handle the case where clipboard access might fail
5. Test with actual speech, not just UI interactions
6. Ensure API key is never committed to repository

## Debugging Tips

- Enable WhisperKit verbose logging for model loading issues
- Use Console.app to view system notifications
- Test with different audio input devices
- Monitor memory usage during long recordings
- Use Xcode Instruments for performance profiling

## Resources

- [WhisperKit Documentation](https://github.com/argmaxinc/WhisperKit)
- [OpenAI API Documentation](https://platform.openai.com/docs)
- [Swift Concurrency Guide](https://developer.apple.com/documentation/swift/concurrency)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)

## Support

For questions or issues during development:
1. Check this CLAUDE.md file first
2. Review the specific GitHub issue requirements
3. Consult the original specification document
4. Ask for help with specific context and code examples

---

**Note**: This document should be updated as the project evolves and new requirements or insights emerge during development.
