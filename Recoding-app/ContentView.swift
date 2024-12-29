//
//  ContentView.swift
//  Recoding-app
//
//  Created by Taylor Galbraith on 12/28/24.
//

import SwiftUI
import AVFoundation

class AudioManager: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingURL: URL?
    
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    
    override init() {
        super.init()
        setupSession()
    }
    
    func setupSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func startRecording() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("recording.m4a")
        recordingURL = audioFilename
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            isRecording = true
        } catch {
            print("Could not start recording: \(error)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
    }
    
    func playRecording() {
        guard let url = recordingURL else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Could not play recording: \(error)")
        }
    }
    
    func stopPlaying() {
        audioPlayer?.stop()
        isPlaying = false
    }
    
    // AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }
}

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Audio Recorder")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            ZStack {
                Circle()
                    .fill(audioManager.isRecording ? Color.red : Color.blue)
                    .frame(width: 150, height: 150)
                
                Image(systemName: audioManager.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            .onTapGesture {
                if audioManager.isRecording {
                    audioManager.stopRecording()
                } else {
                    audioManager.startRecording()
                }
            }
            
            if audioManager.recordingURL != nil {
                Button(action: {
                    if audioManager.isPlaying {
                        audioManager.stopPlaying()
                    } else {
                        audioManager.playRecording()
                    }
                }) {
                    HStack {
                        Image(systemName: audioManager.isPlaying ? "stop.fill" : "play.fill")
                        Text(audioManager.isPlaying ? "Stop Playing" : "Play Recording")
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
    }
}

struct RecordingPermissionView: View {
    @State private var isPermissionGranted = false
    
    var body: some View {
        VStack {
            if isPermissionGranted {
                ContentView()
            } else {
                RequestPermissionView(isPermissionGranted: $isPermissionGranted)
            }
        }
        .onAppear {
            checkPermission()
        }
    }
    
    func checkPermission() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            isPermissionGranted = true
        case .denied:
            isPermissionGranted = false
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    isPermissionGranted = granted
                }
            }
        @unknown default:
            isPermissionGranted = false
        }
    }
}

struct RequestPermissionView: View {
    @Binding var isPermissionGranted: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Microphone Access Required")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Please grant access to your microphone to record audio.")
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            .font(.title2)
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
        }
        .padding()
    }
}

