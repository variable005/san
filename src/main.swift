import SwiftUI
import AppKit
import AVFoundation
import Combine
import UniformTypeIdentifiers

// MARK: - Data Models

struct Track: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let artwork: NSImage?
    
    static func == (lhs: Track, rhs: Track) -> Bool {
        return lhs.id == rhs.id
    }
}

enum NavigationItem: String, CaseIterable, Identifiable {
    case library = "Library"
    case nowPlaying = "Now Playing"
    case playlists = "Playlists"
    case settings = "Settings"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .library: return "music.note.list"
        case .nowPlaying: return "play.circle"
        case .playlists: return "music.quaver.playlist"
        case .settings: return "gearshape"
        }
    }
}

// MARK: - Audio Engine & App State Controller

class AudioEngine: NSObject, ObservableObject, AVAudioPlayerDelegate {
    // Audio Playback State
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 0.8 {
        didSet {
            audioPlayer?.volume = volume
        }
    }
    @Published var currentTrack: Track?
    @Published var playlist: [Track] = []
    @Published var isShuffled: Bool = false
    @Published var isRepeated: Bool = false
    @Published var visualizerLevels: [CGFloat] = Array(repeating: 0.15, count: 16)
    
    // Navigation & UI State
    @Published var selectedNav: NavigationItem = .nowPlaying
    @Published var searchText: String = ""
    @Published var hoveredButtonId: String? = nil
    @Published var hoveredTrackId: UUID? = nil
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var visualizerTimer: Timer?
    
    override init() {
        super.init()
    }
    
    func loadAndPlay(track: Track) {
        currentTrack = track
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: track.url)
            audioPlayer?.delegate = self
            audioPlayer?.volume = volume
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            isPlaying = true
            duration = audioPlayer?.duration ?? track.duration
            currentTime = 0
            
            startTimers()
        } catch {
            print("Failed to play track: \(error.localizedDescription)")
        }
    }
    
    func togglePlay() {
        guard let player = audioPlayer else {
            if let first = playlist.first {
                loadAndPlay(track: first)
            }
            return
        }
        
        if player.isPlaying {
            player.pause()
            isPlaying = false
            stopTimers()
        } else {
            player.play()
            isPlaying = true
            startTimers()
        }
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }
    
    func nextTrack() {
        guard !playlist.isEmpty else { return }
        if isShuffled {
            if let randomTrack = playlist.randomElement() {
                loadAndPlay(track: randomTrack)
            }
        } else if let current = currentTrack, let index = playlist.firstIndex(of: current) {
            let nextIndex = (index + 1) % playlist.count
            loadAndPlay(track: playlist[nextIndex])
        } else {
            loadAndPlay(track: playlist[0])
        }
    }
    
    func previousTrack() {
        guard !playlist.isEmpty else { return }
        if currentTime > 3.0 {
            seek(to: 0)
            return
        }
        if let current = currentTrack, let index = playlist.firstIndex(of: current) {
            let prevIndex = (index - 1 + playlist.count) % playlist.count
            loadAndPlay(track: playlist[prevIndex])
        } else {
            loadAndPlay(track: playlist[0])
        }
    }
    
    // MARK: - File Import & Metadata Extraction
    
    func openFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.audio, .mp3, .wav, .mpeg4Audio]
        
        if panel.runModal() == .OK {
            var newTracks: [Track] = []
            for url in panel.urls {
                if url.hasDirectoryPath {
                    newTracks.append(contentsOf: scanDirectory(url))
                } else {
                    if let track = extractMetadata(from: url) {
                        newTracks.append(track)
                    }
                }
            }
            
            DispatchQueue.main.async {
                let uniqueTracks = newTracks.filter { track in
                    !self.playlist.contains(where: { $0.url == track.url })
                }
                self.playlist.append(contentsOf: uniqueTracks)
                if self.currentTrack == nil, let first = self.playlist.first {
                    self.loadAndPlay(track: first)
                }
            }
        }
    }
    
    private func scanDirectory(_ dirUrl: URL) -> [Track] {
        var results: [Track] = []
        let fileManager = FileManager.default
        let keys: [URLResourceKey] = [.isRegularFileKey]
        
        if let enumerator = fileManager.enumerator(at: dirUrl, includingPropertiesForKeys: keys) {
            for case let fileUrl as URL in enumerator {
                let ext = fileUrl.pathExtension.lowercased()
                if ["mp3", "wav", "m4a", "flac", "aac"].contains(ext) {
                    if let track = extractMetadata(from: fileUrl) {
                        results.append(track)
                    }
                }
            }
        }
        return results
    }
    
    private func extractMetadata(from url: URL) -> Track? {
        let asset = AVURLAsset(url: url)
        var title = url.deletingPathExtension().lastPathComponent
        var artist = "Unknown Artist"
        var album = "Unknown Album"
        var artworkImage: NSImage?
        
        let seconds = CMTimeGetSeconds(asset.duration)
        let trackDuration = seconds.isNaN || seconds <= 0 ? 180.0 : seconds
        
        let formats = asset.availableMetadataFormats
        for format in formats {
            for item in asset.metadata(forFormat: format) {
                if let commonKey = item.commonKey?.rawValue {
                    switch commonKey {
                    case "title":
                        if let val = item.value as? String, !val.isEmpty { title = val }
                    case "artist":
                        if let val = item.value as? String, !val.isEmpty { artist = val }
                    case "albumName":
                        if let val = item.value as? String, !val.isEmpty { album = val }
                    case "artwork":
                        if let data = item.value as? Data, let img = NSImage(data: data) {
                            artworkImage = img
                        }
                    default:
                        break
                    }
                }
            }
        }
        
        return Track(url: url, title: title, artist: artist, album: album, duration: trackDuration, artwork: artworkImage)
    }
    
    // MARK: - Timers & Visualizer
    
    private func startTimers() {
        stopTimers()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.currentTime = player.currentTime
        }
        
        visualizerTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            self.visualizerLevels = (0..<16).map { _ in
                CGFloat.random(in: 0.15...0.9)
            }
        }
    }
    
    private func stopTimers() {
        timer?.invalidate()
        timer = nil
        visualizerTimer?.invalidate()
        visualizerTimer = nil
        visualizerLevels = Array(repeating: 0.15, count: 16)
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            if self.isRepeated, let current = self.currentTrack {
                self.loadAndPlay(track: current)
            } else {
                self.nextTrack()
            }
        }
    }
}

// MARK: - Modern UI Components (Clean, Solid, Minimalist)

struct ModernCard<Content: View>: View {
    var cornerRadius: CGFloat = 16
    @ViewBuilder var content: Content
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(red: 0.13, green: 0.13, blue: 0.14))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
    }
}

struct ModernButton: View {
    let buttonId: String
    let icon: String
    var size: CGFloat = 40
    var iconSize: CGFloat = 16
    var active: Bool = false
    var isPrimary: Bool = false
    @ObservedObject var engine: AudioEngine
    let action: () -> Void
    
    var isHovered: Bool {
        engine.hoveredButtonId == buttonId
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isPrimary {
                    Circle()
                        .fill(Color.white)
                        .frame(width: size, height: size)
                    Image(systemName: icon)
                        .font(.system(size: iconSize, weight: .bold))
                        .foregroundColor(.black)
                } else {
                    Circle()
                        .fill(active ? Color.white.opacity(0.18) : (isHovered ? Color.white.opacity(0.1) : Color.white.opacity(0.05)))
                        .frame(width: size, height: size)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    Image(systemName: icon)
                        .font(.system(size: iconSize, weight: .medium))
                        .foregroundColor(active ? .white : Color.white.opacity(0.7))
                }
            }
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            engine.hoveredButtonId = hovering ? buttonId : nil
        }
    }
}

struct ArtworkView: View {
    let artwork: NSImage?
    var size: CGFloat = 180
    
    var body: some View {
        Group {
            if let art = artwork {
                Image(nsImage: art)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Color(red: 0.18, green: 0.18, blue: 0.20)
                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.35, weight: .light))
                        .foregroundColor(Color.white.opacity(0.4))
                }
            }
        }
        .frame(width: size, height: size)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 6)
    }
}

struct ModernVisualizerView: View {
    let levels: [CGFloat]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<levels.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 4, height: max(4, levels[index] * 36))
                    .animation(.easeInOut(duration: 0.1), value: levels[index])
            }
        }
        .frame(height: 40)
    }
}

// MARK: - Main Application View

struct ContentView: View {
    @StateObject private var engine = AudioEngine()
    
    var filteredPlaylist: [Track] {
        if engine.searchText.isEmpty {
            return engine.playlist
        } else {
            return engine.playlist.filter {
                $0.title.localizedCaseInsensitiveContains(engine.searchText) ||
                $0.artist.localizedCaseInsensitiveContains(engine.searchText) ||
                $0.album.localizedCaseInsensitiveContains(engine.searchText)
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Modern Solid Dark Background
            Color(red: 0.08, green: 0.08, blue: 0.09)
                .ignoresSafeArea()
            
            // Main Window Content Layout
            HStack(spacing: 0) {
                // MARK: Sidebar Navigation
                VStack(alignment: .leading, spacing: 24) {
                    // App Brand Header
                    HStack(spacing: 12) {
                        Image(systemName: "music.note.house.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("SAN")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    
                    // Navigation List
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(NavigationItem.allCases) { item in
                            Button(action: { engine.selectedNav = item }) {
                                HStack(spacing: 12) {
                                    Image(systemName: item.iconName)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(engine.selectedNav == item ? .white : Color.white.opacity(0.5))
                                    Text(item.rawValue)
                                        .font(.system(size: 13, weight: engine.selectedNav == item ? .semibold : .medium))
                                        .foregroundColor(engine.selectedNav == item ? .white : Color.white.opacity(0.6))
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(engine.selectedNav == item ? Color.white.opacity(0.1) : Color.clear)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 12)
                    
                    Spacer()
                    
                    // Add Music File Button
                    Button(action: { engine.openFiles() }) {
                        HStack {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Import Music")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
                .frame(width: 200)
                .background(Color(red: 0.10, green: 0.10, blue: 0.11))
                
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 1)
                
                // MARK: Main Content Workspace
                VStack(spacing: 0) {
                    // Header Bar
                    HStack {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Color.white.opacity(0.4))
                                .font(.system(size: 13))
                            TextField("Search tracks, artists...", text: $engine.searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .foregroundColor(.white)
                                .font(.system(size: 13))
                        }
                        .padding(.vertical, 7)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.06))
                        )
                        .frame(maxWidth: 320)
                        
                        Spacer()
                        
                        Text("\(engine.playlist.count) tracks")
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 18)
                    .padding(.bottom, 16)
                    
                    // Main Scroll Area
                    ScrollView {
                        VStack(spacing: 24) {
                            if engine.selectedNav == .nowPlaying || engine.playlist.isEmpty {
                                // Now Playing Stage
                                ModernCard(cornerRadius: 16) {
                                    if let track = engine.currentTrack {
                                        HStack(spacing: 28) {
                                            ArtworkView(artwork: track.artwork, size: 160)
                                            
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text(track.title)
                                                    .font(.system(size: 24, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                                
                                                Text(track.artist)
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(Color.white.opacity(0.7))
                                                
                                                Text(track.album)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(Color.white.opacity(0.4))
                                                
                                                ModernVisualizerView(levels: engine.visualizerLevels)
                                                    .padding(.top, 8)
                                            }
                                            Spacer()
                                        }
                                        .padding(24)
                                    } else {
                                        VStack(spacing: 14) {
                                            Image(systemName: "music.note")
                                                .font(.system(size: 40, weight: .light))
                                                .foregroundColor(Color.white.opacity(0.4))
                                            Text("No Track Playing")
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.white)
                                            Text("Click 'Import Music' to select local audio files")
                                                .font(.system(size: 13))
                                                .foregroundColor(Color.white.opacity(0.4))
                                            
                                            Button(action: { engine.openFiles() }) {
                                                Text("Open Files")
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 20)
                                                    .padding(.vertical, 8)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(Color.white.opacity(0.12))
                                                    )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                        .padding(36)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                            
                            // Library List View
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Library Tracks")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                
                                if filteredPlaylist.isEmpty {
                                    VStack {
                                        Text("No music in library yet.")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color.white.opacity(0.4))
                                            .padding(24)
                                    }
                                } else {
                                    VStack(spacing: 2) {
                                        ForEach(Array(filteredPlaylist.enumerated()), id: \.element.id) { index, track in
                                            let isHovered = engine.hoveredTrackId == track.id
                                            let isSelected = engine.currentTrack == track
                                            
                                            HStack(spacing: 14) {
                                                Text("\(index + 1)")
                                                    .font(.system(size: 12, design: .monospaced))
                                                    .foregroundColor(Color.white.opacity(0.4))
                                                    .frame(width: 24, alignment: .trailing)
                                                
                                                ArtworkView(artwork: track.artwork, size: 32)
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(track.title)
                                                        .font(.system(size: 13, weight: .medium))
                                                        .foregroundColor(isSelected ? .white : Color.white.opacity(0.9))
                                                        .lineLimit(1)
                                                    Text(track.artist)
                                                        .font(.system(size: 11))
                                                        .foregroundColor(Color.white.opacity(0.5))
                                                        .lineLimit(1)
                                                }
                                                
                                                Spacer()
                                                
                                                Text(track.album)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Color.white.opacity(0.4))
                                                    .frame(width: 140, alignment: .leading)
                                                    .lineLimit(1)
                                                
                                                Text(formatTime(track.duration))
                                                    .font(.system(size: 12, design: .monospaced))
                                                    .foregroundColor(Color.white.opacity(0.4))
                                                
                                                Button(action: { engine.loadAndPlay(track: track) }) {
                                                    Image(systemName: isSelected && engine.isPlaying ? "pause.fill" : "play.fill")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.white)
                                                        .padding(6)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(isSelected ? Color.white.opacity(0.12) : (isHovered ? Color.white.opacity(0.05) : Color.clear))
                                            )
                                            .onHover { hovering in
                                                engine.hoveredTrackId = hovering ? track.id : nil
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // MARK: Bottom Player Bar
                    VStack(spacing: 8) {
                        Rectangle()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 1)
                        
                        // Scrubbing Progress Bar
                        HStack(spacing: 10) {
                            Text(formatTime(engine.currentTime))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.4))
                            
                            Slider(value: Binding(
                                get: { engine.currentTime },
                                set: { engine.seek(to: $0) }
                            ), in: 0...max(1, engine.duration))
                            .accentColor(.white)
                            
                            Text(formatTime(engine.duration))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.4))
                        }
                        .padding(.horizontal, 20)
                        
                        // Transport Controls
                        HStack(spacing: 20) {
                            // Current Song Info
                            HStack(spacing: 10) {
                                ArtworkView(artwork: engine.currentTrack?.artwork, size: 36)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(engine.currentTrack?.title ?? "No Song Playing")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Text(engine.currentTrack?.artist ?? "Select a track")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color.white.opacity(0.5))
                                        .lineLimit(1)
                                }
                            }
                            .frame(width: 220, alignment: .leading)
                            
                            Spacer()
                            
                            // Buttons
                            HStack(spacing: 14) {
                                ModernButton(buttonId: "shuffle", icon: "shuffle", size: 32, iconSize: 13, active: engine.isShuffled, engine: engine) {
                                    engine.isShuffled.toggle()
                                }
                                
                                ModernButton(buttonId: "prev", icon: "backward.fill", size: 36, iconSize: 14, engine: engine) {
                                    engine.previousTrack()
                                }
                                
                                ModernButton(buttonId: "play", icon: engine.isPlaying ? "pause.fill" : "play.fill", size: 44, iconSize: 18, isPrimary: true, engine: engine) {
                                    engine.togglePlay()
                                }
                                
                                ModernButton(buttonId: "next", icon: "forward.fill", size: 36, iconSize: 14, engine: engine) {
                                    engine.nextTrack()
                                }
                                
                                ModernButton(buttonId: "repeat", icon: "repeat", size: 32, iconSize: 13, active: engine.isRepeated, engine: engine) {
                                    engine.isRepeated.toggle()
                                }
                            }
                            
                            Spacer()
                            
                            // Volume Slider
                            HStack(spacing: 8) {
                                Image(systemName: engine.volume == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                    .foregroundColor(Color.white.opacity(0.5))
                                    .font(.system(size: 12))
                                
                                Slider(value: $engine.volume, in: 0...1)
                                    .accentColor(.white)
                                    .frame(width: 85)
                            }
                            .frame(width: 200, alignment: .trailing)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                    }
                    .background(Color(red: 0.11, green: 0.11, blue: 0.12))
                }
            }
        }
        .frame(minWidth: 960, minHeight: 640)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        guard !seconds.isNaN && seconds >= 0 else { return "00:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - App Delegate & Main Entry

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup Status Bar Menu Item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "San")
            button.action = #selector(statusBarButtonClicked)
        }
    }
    
    @objc func statusBarButtonClicked() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
}

@main
struct SanApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}
