# VoiceFlow

A macOS voice transcription application built with SwiftUI that aims to provide seamless speech-to-text conversion with AI-powered text processing capabilities.

## 🎯 Project Vision

VoiceFlow is designed to be a lightweight, floating macOS application that:

- **Captures voice input** through the system microphone
- **Transcribes speech to text** using advanced speech recognition
- **Processes transcribed text** with AI/LLM integration for refinement and enhancement
- **Provides quick access** via a compact, always-on-top floating window
- **Offers seamless workflow integration** with copy-to-clipboard functionality

The goal is to create a productivity tool that makes voice-to-text conversion as frictionless as possible for macOS users.

## 📋 Current Status

**⚠️ Early Development Stage**

This project is currently in the foundational development phase. Here's what's implemented vs. planned:

### ✅ What Works Now
- **Basic UI Structure**: Floating 400x530 window with title bar
- **Component Architecture**: Separated button components (Copy, Record, Magic Wand)
- **Visual States**: Button hover effects, loading overlays, and basic state management
- **Dark Mode Support**: Adaptive colors for light/dark themes
- **Debug Interface**: Development tools for testing UI interactions
- **Clipboard Integration**: Basic text copying functionality

### 🚧 In Progress / Missing
- **Voice Recording**: No actual microphone capture implemented
- **Speech Recognition**: No speech-to-text processing
- **AI Integration**: Magic wand processing is currently simulated
- **Error Handling**: Limited error states and user feedback
- **Persistence**: No data storage or session management
- **Audio Permissions**: Basic setup present but not fully integrated

### 🎨 UI Preview

The application features a clean, minimal interface with:
- Prominent "VOICE FLOW" title
- Text display area with scrollable content
- Three main action buttons: Copy, Record, and Magic Wand
- Loading states with progress indicators
- Accessibility support with VoiceOver labels

## 🏗️ Architecture

Built using modern SwiftUI patterns:

```
VoiceFlow/
├── Views/
│   ├── ContentView.swift          # Main application view
│   ├── ButtonComponent.swift      # Reusable button base
│   ├── CopyButton.swift          # Clipboard copy functionality
│   ├── RecordButton.swift        # Voice recording control
│   ├── MagicWandButton.swift     # AI processing trigger
│   └── TextDisplayView.swift     # Transcription display area
├── VoiceFlowApp.swift            # App entry point and window config
└── Info.plist                   # Permissions and metadata
```

## 🛠️ Development Context

### Hackathon Project
This was developed as a small hackathon project to explore modern AI-assisted development workflows. The focus was on rapid prototyping and experimenting with LLM-powered code generation tools.

### Tools Used
- **[Claude Code](https://www.anthropic.com/claude-code)**: AI-powered command line coding assistant
- **[Claude](https://claude.ai)**: LLM for code review, architecture planning, and documentation
- **[Xcode MCP Server](https://github.com/cameroncooke/XcodeBuildMCP)**: Model Context Protocol integration for Xcode
- **[GitHub MCP Server](https://github.com/github/github-mcp-server)**: Git workflow automation and PR management

### Development Workflow
The development process was heavily influenced by the LLM workflow described in this [blog post about LLM codegen workflow](https://harper.blog/2025/02/16/my-llm-codegen-workflow-atm/), emphasizing:
- AI-assisted code generation and iteration
- Automated code review and feedback
- Rapid prototyping with intelligent tooling
- Integration of multiple AI services in the development pipeline

## 🚀 Getting Started

### Prerequisites
- macOS 12.0 or later
- Xcode 14.0 or later
- Swift 5.7 or later

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/nicerice/VoiceFlow.git
   ```

2. Open the project in Xcode:
   ```bash
   cd VoiceFlow
   open VoiceFlow.xcodeproj
   ```

3. Build and run the project (⌘+R)

### Current Functionality
- **Test the UI**: Use the debug buttons to simulate text input and loading states
- **Copy Feature**: Add sample text and test the clipboard functionality
- **Button States**: Observe how buttons enable/disable based on application state
- **Dark Mode**: Toggle system appearance to test theme adaptation

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 🔗 Links

- **Repository**: https://github.com/nicerice/VoiceFlow
- **Blog post about LLM workflow**: https://harper.blog/2025/02/16/my-llm-codegen-workflow-atm/
- **Claude Code**: https://www.anthropic.com/claude-code
- **Claude**: https://claude.ai
- **Xcode MCP Server**: https://github.com/cameroncooke/XcodeBuildMCP
- **GitHub MCP Server**: https://github.com/github/github-mcp-server

---

*Built with ❤️ and AI assistance during a weekend hackathon*