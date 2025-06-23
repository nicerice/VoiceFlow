//
//  AudioRecorder.swift
//  VoiceFlow
//
//  Created by Sebastian Reimann on 23.06.25.
//

import Foundation
import AVFoundation

#if os(macOS)
import AppKit

// Custom permission enum for macOS compatibility
enum AudioPermissionStatus {
    case granted
    case denied
}
#endif

@MainActor
class AudioRecorder: ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?
    
    @Published var isRecording = false
    
    #if os(iOS)
    @Published var permissionStatus: AVAudioSession.RecordPermission = .denied
    #else
    @Published var permissionStatus: AudioPermissionStatus = .denied
    #endif
    
    init() {
        checkPermissionStatus()
    }
    
    // MARK: - Permission Handling
    
    func checkPermissionStatus() {
        #if os(iOS)
        permissionStatus = AVAudioSession.sharedInstance().recordPermission
        #else
        // On macOS, check microphone permission status
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            permissionStatus = .granted
        case .denied, .restricted:
            permissionStatus = .denied
        case .notDetermined:
            permissionStatus = .denied // We'll treat undetermined as denied initially
        @unknown default:
            permissionStatus = .denied
        }
        #endif
    }
    
    func requestPermission() async -> Bool {
        #if os(iOS)
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                Task { @MainActor in
                    self.permissionStatus = granted ? .granted : .denied
                    continuation.resume(returning: granted)
                }
            }
        }
        #else
        // On macOS, request microphone permission
        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                Task { @MainActor in
                    self.permissionStatus = granted ? .granted : .denied
                    continuation.resume(returning: granted)
                }
            }
        }
        #endif
    }
    
    func ensurePermission() async throws {
        checkPermissionStatus() // Update current status
        
        switch permissionStatus {
        case .granted:
            return
        case .denied:
            // Try to request permission if it was denied
            let granted = await requestPermission()
            if !granted {
                throw VoiceFlowError.permissionDenied
            }
        @unknown default:
            throw VoiceFlowError.permissionDenied
        }
    }
    
    // MARK: - Audio Session Management
    
    func configureAudioSession() throws {
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        
        try audioSession.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.defaultToSpeaker, .allowBluetooth]
        )
        
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        #else
        // On macOS, audio session configuration is handled differently
        print("Audio session configuration (macOS)")
        #endif
    }
    
    func deactivateAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
        #else
        print("Audio session deactivation (macOS)")
        #endif
    }
    
    // MARK: - Recording Management
    
    func startRecording() async throws -> URL {
        try await ensurePermission()
        try configureAudioSession()
        
        // Clean up old recordings first
        cleanupOldRecordings()
        
        // Create temporary file for recording
        let audioFilename = createRecordingURL()
        recordingURL = audioFilename
        
        // Setup audio engine
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw VoiceFlowError.recordingSetupFailed
        }
        
        inputNode = audioEngine.inputNode
        guard let inputNode = inputNode else {
            throw VoiceFlowError.recordingSetupFailed
        }
        
        // Configure optimal recording format for speech (16kHz, mono)
        let recordingFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        )
        
        guard let format = recordingFormat else {
            throw VoiceFlowError.recordingSetupFailed
        }
        
        // Create audio file with optimized settings
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
        
        do {
            audioFile = try AVAudioFile(forWriting: audioFilename, settings: settings)
        } catch {
            throw VoiceFlowError.recordingSetupFailed
        }
        
        guard let audioFile = audioFile else {
            throw VoiceFlowError.recordingSetupFailed
        }
        
        // Install tap on input node with format conversion
        let inputFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            
            do {
                // Convert to our desired format if needed
                if inputFormat.sampleRate != format.sampleRate || inputFormat.channelCount != format.channelCount {
                    // For now, write directly - format conversion can be added later
                    try audioFile.write(from: buffer)
                } else {
                    try audioFile.write(from: buffer)
                }
            } catch {
                print("Error writing audio buffer: \(error)")
            }
        }
        
        // Start audio engine
        do {
            try audioEngine.start()
            isRecording = true
            print("Recording started with format: \(inputFormat)")
            return audioFilename
        } catch {
            inputNode.removeTap(onBus: 0)
            throw VoiceFlowError.recordingStartFailed
        }
    }
    
    func stopRecording() -> URL? {
        guard isRecording, let audioEngine = audioEngine, let inputNode = inputNode else {
            return nil
        }
        
        // Stop engine and remove tap
        audioEngine.stop()
        inputNode.removeTap(onBus: 0)
        
        // Reset state
        isRecording = false
        audioFile = nil
        self.audioEngine = nil
        self.inputNode = nil
        
        deactivateAudioSession()
        
        print("Recording stopped")
        return recordingURL
    }
    
    func cancelRecording() {
        if let audioURL = stopRecording() {
            // Delete the recording file
            try? FileManager.default.removeItem(at: audioURL)
        }
    }
    
    // MARK: - File Management
    
    private func createRecordingURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timestamp = Int(Date().timeIntervalSince1970)
        return documentsPath.appendingPathComponent("recording_\(timestamp).wav")
    }
    
    private func cleanupOldRecordings() {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: documentsPath,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            
            let recordingFiles = fileURLs.filter { $0.lastPathComponent.hasPrefix("recording_") }
            let cutoffDate = Date().addingTimeInterval(-24 * 60 * 60) // 24 hours ago
            
            for fileURL in recordingFiles {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.creationDateKey])
                    if let creationDate = resourceValues.creationDate, creationDate < cutoffDate {
                        try FileManager.default.removeItem(at: fileURL)
                        print("Cleaned up old recording: \(fileURL.lastPathComponent)")
                    }
                } catch {
                    print("Error cleaning up file \(fileURL.lastPathComponent): \(error)")
                }
            }
        } catch {
            print("Error cleaning up old recordings: \(error)")
        }
    }
    
    func getRecordingFileSize(url: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
}

// MARK: - Error Types

enum VoiceFlowError: LocalizedError {
    case permissionDenied
    case recordingSetupFailed
    case recordingStartFailed
    case transcriptionFailed
    case llmProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission is required to record audio. Please grant permission in System Preferences."
        case .recordingSetupFailed:
            return "Failed to set up audio recording. Please check your microphone."
        case .recordingStartFailed:
            return "Failed to start recording. Please try again."
        case .transcriptionFailed:
            return "Failed to transcribe audio. Please try recording again."
        case .llmProcessingFailed:
            return "Failed to process text with AI. Please try again."
        }
    }
}