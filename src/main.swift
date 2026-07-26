import SwiftUI
import AppKit
import AVFoundation
import MediaPlayer
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
    case favorites = "Favorites"
    case playlists = "Playlists"
    case equalizer = "Equalizer"
    case settings = "Settings"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .library: return "music.note.list"
        case .nowPlaying: return "play.circle"
        case .favorites: return "heart.fill"
        case .playlists: return "music.quaver.playlist"
        case .equalizer: return "slider.vertical.3"
        case .settings: return "gearshape"
        }
    }
}

struct SavedLibraryData: Codable {
    var filePaths: [String]
    var favoritePaths: [String]?
    var eqGains: [Float]?
}

enum EQPreset: String, CaseIterable, Identifiable {
    case flat = "Flat"
    case bassBoost = "Bass Boost"
    case trebleBoost = "Treble Boost"
    case vocal = "Vocal"
    case electronic = "Electronic"
    
    var id: String { self.rawValue }
    
    var gains: [Float] {
        switch self {
        case .flat: return [0, 0, 0, 0, 0]
        case .bassBoost: return [6, 4, 0, 0, 0]
        case .trebleBoost: return [0, 0, 0, 4, 6]
        case .vocal: return [-2, 2, 5, 3, 0]
        case .electronic: return [5, 3, 0, 2, 4]
        }
    }
}

struct LyricLine: Identifiable, Equatable {
    let id = UUID()
    let time: TimeInterval
    let text: String
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
    @Published var favoritePaths: Set<String> = []
    @Published var isShuffled: Bool = false
    @Published var isRepeated: Bool = false
    @Published var visualizerLevels: [CGFloat] = Array(repeating: 0.15, count: 16)
    
    // Equalizer State (5 Bands: 60Hz, 230Hz, 910Hz, 3.6kHz, 14kHz)
    @Published var selectedEQPreset: EQPreset = .flat
    @Published var eqGains: [Float] = [0, 0, 0, 0, 0]
    
    // Lyrics State
    @Published var currentLyrics: [LyricLine] = []
    @Published var activeLyricIndex: Int? = nil
    
    // Navigation & UI State
    @Published var selectedNav: NavigationItem = .nowPlaying
    @Published var searchText: String = ""
    @Published var hoveredButtonId: String? = nil
    @Published var hoveredTrackId: UUID? = nil
    @Published var isDropTargeted: Bool = false
    @Published var isMiniPlayer: Bool = false
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var visualizerTimer: Timer?
    
    override init() {
        super.init()
        setupRemoteCommandCenter()
        loadLibrary()
    }
    
    // MARK: - Media Keys & Remote Command Center
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.togglePlay()
            return .success
        }
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.togglePlay()
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlay()
            return .success
        }
        
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.nextTrack()
            return .success
        }
        
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.previousTrack()
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let posEvent = event as? MPChangePlaybackPositionCommandEvent {
                self?.seek(to: posEvent.positionTime)
                return .success
            }
            return .commandFailed
        }
    }
    
    // MARK: - Control Center & Lock Screen Sync
    
    func updateNowPlayingInfo() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyAlbumTitle: track.album,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        
        if let artwork = track.artwork {
            let mpArtwork = MPMediaItemArtwork(boundsSize: artwork.size) { _ in artwork }
            info[MPMediaItemPropertyArtwork] = mpArtwork
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    // MARK: - Playback Logic
    
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
            
            loadLyrics(for: track)
            startTimers()
            updateNowPlayingInfo()
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
        updateNowPlayingInfo()
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
        updateActiveLyric(time: time)
        updateNowPlayingInfo()
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
    
    // MARK: - Favorites System
    
    func isFavorite(track: Track) -> Bool {
        return favoritePaths.contains(track.url.path)
    }
    
    func toggleFavorite(track: Track) {
        let path = track.url.path
        if favoritePaths.contains(path) {
            favoritePaths.remove(path)
        } else {
            favoritePaths.insert(path)
        }
        saveLibrary()
    }
    
    // MARK: - Equalizer Controls
    
    func applyEQPreset(_ preset: EQPreset) {
        selectedEQPreset = preset
        eqGains = preset.gains
        saveLibrary()
    }
    
    // MARK: - Synced Lyrics Engine (.lrc & Embedded)
    
    private func loadLyrics(for track: Track) {
        currentLyrics = []
        activeLyricIndex = nil
        
        let lrcURL = track.url.deletingPathExtension().appendingPathExtension("lrc")
        if FileManager.default.fileExists(atPath: lrcURL.path),
           let content = try? String(contentsOf: lrcURL, encoding: .utf8) {
            currentLyrics = parseLRC(content)
            return
        }
        
        // Fallback to embedded metadata lyrics if available
        let asset = AVURLAsset(url: track.url)
        for format in asset.availableMetadataFormats {
            for item in asset.metadata(forFormat: format) {
                if let val = item.value as? String, item.commonKey?.rawValue == "lyrics" || item.identifier?.rawValue.contains("USLT") == true {
                    let lines = val.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                    currentLyrics = lines.enumerated().map { index, line in
                        LyricLine(time: TimeInterval(index * 4), text: line)
                    }
                    return
                }
            }
        }
    }
    
    private func parseLRC(_ text: String) -> [LyricLine] {
        var lines: [LyricLine] = []
        let pattern = "\\[(\\d{2}):(\\d{2})\\.(\\d{2,3})\\](.*)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        
        let rawLines = text.components(separatedBy: .newlines)
        for rawLine in rawLines {
            let nsString = rawLine as NSString
            let matches = regex.matches(in: rawLine, range: NSRange(location: 0, length: nsString.length))
            if let match = matches.first, match.numberOfRanges >= 5 {
                let minStr = nsString.substring(with: match.range(at: 1))
                let secStr = nsString.substring(with: match.range(at: 2))
                let msStr = nsString.substring(with: match.range(at: 3))
                let lyricText = nsString.substring(with: match.range(at: 4)).trimmingCharacters(in: .whitespaces)
                
                let mins = Double(minStr) ?? 0
                let secs = Double(secStr) ?? 0
                let ms = Double(msStr) ?? 0
                let time = mins * 60.0 + secs + (msStr.count == 3 ? ms / 1000.0 : ms / 100.0)
                
                if !lyricText.isEmpty {
                    lines.append(LyricLine(time: time, text: lyricText))
                }
            }
        }
        return lines.sorted { $0.time < $1.time }
    }
    
    private func updateActiveLyric(time: TimeInterval) {
        guard !currentLyrics.isEmpty else {
            activeLyricIndex = nil
            return
        }
        var foundIndex: Int? = nil
        for (index, line) in currentLyrics.enumerated() {
            if time >= line.time {
                foundIndex = index
            } else {
                break
            }
        }
        activeLyricIndex = foundIndex
    }
    
    // MARK: - File Import & Drag and Drop
    
    func handleDroppedURLs(_ urls: [URL]) {
        var newTracks: [Track] = []
        for url in urls {
            if url.hasDirectoryPath {
                newTracks.append(contentsOf: scanDirectory(url))
            } else {
                let ext = url.pathExtension.lowercased()
                if ["mp3", "wav", "m4a", "flac", "aac"].contains(ext) {
                    if let track = extractMetadata(from: url) {
                        newTracks.append(track)
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            let uniqueTracks = newTracks.filter { track in
                !self.playlist.contains(where: { $0.url == track.url })
            }
            self.playlist.append(contentsOf: uniqueTracks)
            self.saveLibrary()
            if self.currentTrack == nil, let first = self.playlist.first {
                self.loadAndPlay(track: first)
            }
        }
    }
    
    func openFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.audio, .mp3, .wav, .mpeg4Audio]
        
        if panel.runModal() == .OK {
            handleDroppedURLs(panel.urls)
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
    
    // MARK: - Mini Player Toggle
    
    func toggleMiniPlayer() {
        isMiniPlayer.toggle()
        if let window = NSApp.windows.first {
            if isMiniPlayer {
                window.setContentSize(NSSize(width: 340, height: 140))
                window.level = .floating
            } else {
                window.setContentSize(NSSize(width: 960, height: 640))
                window.level = .normal
            }
        }
    }
    
    // MARK: - Persistent Storage (library.json)
    
    private var libraryStorageURL: URL {
        let fileManager = FileManager.default
        let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let sanDir = appSupportDir.appendingPathComponent("San", isDirectory: true)
        try? fileManager.createDirectory(at: sanDir, withIntermediateDirectories: true)
        return sanDir.appendingPathComponent("library.json")
    }
    
    func saveLibrary() {
        let paths = playlist.map { $0.url.path }
        let savedData = SavedLibraryData(filePaths: paths, favoritePaths: Array(favoritePaths), eqGains: eqGains)
        do {
            let json = try JSONEncoder().encode(savedData)
            try json.write(to: libraryStorageURL)
        } catch {
            print("Failed to save library: \(error.localizedDescription)")
        }
    }
    
    func loadLibrary() {
        let url = libraryStorageURL
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let savedData = try JSONDecoder().decode(SavedLibraryData.self, from: data)
            
            if let favs = savedData.favoritePaths {
                self.favoritePaths = Set(favs)
            }
            if let gains = savedData.eqGains, gains.count == 5 {
                self.eqGains = gains
            }
            
            var loadedTracks: [Track] = []
            for path in savedData.filePaths {
                let fileURL = URL(fileURLWithPath: path)
                if FileManager.default.fileExists(atPath: path), let track = extractMetadata(from: fileURL) {
                    loadedTracks.append(track)
                }
            }
            
            DispatchQueue.main.async {
                self.playlist = loadedTracks
                if self.currentTrack == nil, let first = self.playlist.first {
                    self.currentTrack = first
                    self.duration = first.duration
                    self.loadLyrics(for: first)
                    self.updateNowPlayingInfo()
                }
            }
        } catch {
            print("Failed to load saved library: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Timers & Visualizer
    
    private func startTimers() {
        stopTimers()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.currentTime = player.currentTime
            self.updateActiveLyric(time: player.currentTime)
            self.updateNowPlayingInfo()
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

// MARK: - Modern UI Components

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

// MARK: - Mini Player Layout View

struct MiniPlayerView: View {
    @ObservedObject var engine: AudioEngine
    
    var body: some View {
        ZStack {
            Color(red: 0.10, green: 0.10, blue: 0.11)
                .ignoresSafeArea()
            
            HStack(spacing: 12) {
                ArtworkView(artwork: engine.currentTrack?.artwork, size: 64)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(engine.currentTrack?.title ?? "No Song Playing")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(engine.currentTrack?.artist ?? "Select a track")
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.5))
                        .lineLimit(1)
                    
                    // Transport controls
                    HStack(spacing: 10) {
                        Button(action: { engine.previousTrack() }) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }.buttonStyle(PlainButtonStyle())
                        
                        Button(action: { engine.togglePlay() }) {
                            Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }.buttonStyle(PlainButtonStyle())
                        
                        Button(action: { engine.nextTrack() }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }.buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        Button(action: { engine.toggleMiniPlayer() }) {
                            Image(systemName: "rectangle.expand.vertical")
                                .font(.system(size: 11))
                                .foregroundColor(Color.white.opacity(0.6))
                        }.buttonStyle(PlainButtonStyle())
                    }
                    .padding(.top, 4)
                }
            }
            .padding(12)
        }
    }
}

// MARK: - Equalizer View Component

struct EqualizerView: View {
    @ObservedObject var engine: AudioEngine
    let bandLabels = ["60Hz", "230Hz", "910Hz", "3.6kHz", "14kHz"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Graphic Equalizer")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            // Preset Buttons
            HStack(spacing: 10) {
                ForEach(EQPreset.allCases) { preset in
                    Button(action: { engine.applyEQPreset(preset) }) {
                        Text(preset.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(engine.selectedEQPreset == preset ? .black : .white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(engine.selectedEQPreset == preset ? Color.white : Color.white.opacity(0.1))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // EQ Band Sliders
            ModernCard(cornerRadius: 16) {
                HStack(spacing: 32) {
                    ForEach(0..<5, id: \.self) { index in
                        VStack(spacing: 12) {
                            Text(String(format: "+%.0fdB", engine.eqGains[index]))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.6))
                            
                            Slider(value: Binding(
                                get: { Double(engine.eqGains[index]) },
                                set: {
                                    engine.eqGains[index] = Float($0)
                                    engine.saveLibrary()
                                }
                            ), in: -12...12)
                            .rotationEffect(.degrees(-90))
                            .frame(width: 140, height: 40)
                            
                            Text(bandLabels[index])
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color.white.opacity(0.8))
                        }
                    }
                }
                .padding(32)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Main Application View

struct ContentView: View {
    @StateObject private var engine = AudioEngine()
    
    var filteredPlaylist: [Track] {
        var baseList = engine.playlist
        if engine.selectedNav == .favorites {
            baseList = baseList.filter { engine.isFavorite(track: $0) }
        }
        
        if engine.searchText.isEmpty {
            return baseList
        } else {
            return baseList.filter {
                $0.title.localizedCaseInsensitiveContains(engine.searchText) ||
                $0.artist.localizedCaseInsensitiveContains(engine.searchText) ||
                $0.album.localizedCaseInsensitiveContains(engine.searchText)
            }
        }
    }
    
    var body: some View {
        Group {
            if engine.isMiniPlayer {
                MiniPlayerView(engine: engine)
            } else {
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
                                
                                Button(action: { engine.toggleMiniPlayer() }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "rectangle.compress.vertical")
                                            .font(.system(size: 12))
                                        Text("Mini Player")
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .foregroundColor(Color.white.opacity(0.7))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(Color.white.opacity(0.08)))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
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
                                    if engine.selectedNav == .equalizer {
                                        EqualizerView(engine: engine)
                                    } else {
                                        if engine.selectedNav == .nowPlaying || engine.playlist.isEmpty {
                                            // Now Playing Stage with Synced Lyrics
                                            ModernCard(cornerRadius: 16) {
                                                if let track = engine.currentTrack {
                                                    HStack(alignment: .top, spacing: 28) {
                                                        VStack(alignment: .leading, spacing: 14) {
                                                            ArtworkView(artwork: track.artwork, size: 160)
                                                            
                                                            HStack {
                                                                VStack(alignment: .leading, spacing: 4) {
                                                                    Text(track.title)
                                                                        .font(.system(size: 20, weight: .bold))
                                                                        .foregroundColor(.white)
                                                                        .lineLimit(1)
                                                                    
                                                                    Text(track.artist)
                                                                        .font(.system(size: 14, weight: .medium))
                                                                        .foregroundColor(Color.white.opacity(0.7))
                                                                }
                                                                Spacer()
                                                                
                                                                Button(action: { engine.toggleFavorite(track: track) }) {
                                                                    Image(systemName: engine.isFavorite(track: track) ? "heart.fill" : "heart")
                                                                        .font(.system(size: 18))
                                                                        .foregroundColor(engine.isFavorite(track: track) ? .red : Color.white.opacity(0.6))
                                                                }
                                                                .buttonStyle(PlainButtonStyle())
                                                            }
                                                            
                                                            ModernVisualizerView(levels: engine.visualizerLevels)
                                                        }
                                                        .frame(width: 220)
                                                        
                                                        // Synced Lyrics Display
                                                        VStack(alignment: .leading, spacing: 10) {
                                                            Text("Lyrics")
                                                                .font(.system(size: 14, weight: .bold))
                                                                .foregroundColor(Color.white.opacity(0.6))
                                                            
                                                            if engine.currentLyrics.isEmpty {
                                                                VStack {
                                                                    Spacer()
                                                                    Text("No synced lyrics found (.lrc)")
                                                                        .font(.system(size: 13))
                                                                        .foregroundColor(Color.white.opacity(0.4))
                                                                    Spacer()
                                                                }
                                                                .frame(maxWidth: .infinity, maxHeight: 180)
                                                            } else {
                                                                ScrollViewReader { proxy in
                                                                    ScrollView {
                                                                        VStack(alignment: .leading, spacing: 10) {
                                                                            ForEach(Array(engine.currentLyrics.enumerated()), id: \.element.id) { idx, line in
                                                                                let isActive = engine.activeLyricIndex == idx
                                                                                Text(line.text)
                                                                                    .font(.system(size: isActive ? 16 : 13, weight: isActive ? .bold : .regular))
                                                                                    .foregroundColor(isActive ? .white : Color.white.opacity(0.35))
                                                                                    .id(idx)
                                                                            }
                                                                        }
                                                                    }
                                                                    .onChange(of: engine.activeLyricIndex) { newIndex in
                                                                        if let index = newIndex {
                                                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                                                proxy.scrollTo(index, anchor: .center)
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                                .frame(maxHeight: 200)
                                                            }
                                                        }
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                    }
                                                    .padding(24)
                                                } else {
                                                    VStack(spacing: 14) {
                                                        Image(systemName: "arrow.down.doc.fill")
                                                            .font(.system(size: 40, weight: .light))
                                                            .foregroundColor(Color.white.opacity(0.4))
                                                        Text("Drag & Drop Music Files Here")
                                                            .font(.system(size: 18, weight: .semibold))
                                                            .foregroundColor(.white)
                                                        Text("Or click 'Import Music' to select audio files from Finder")
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
                                            Text(engine.selectedNav == .favorites ? "Favorite Tracks" : "Library Tracks")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 24)
                                            
                                            if filteredPlaylist.isEmpty {
                                                VStack {
                                                    Text(engine.selectedNav == .favorites ? "No favorite tracks added yet." : "No music in library yet. Drag and drop audio files anywhere!")
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
                                                            
                                                            Button(action: { engine.toggleFavorite(track: track) }) {
                                                                Image(systemName: engine.isFavorite(track: track) ? "heart.fill" : "heart")
                                                                    .font(.system(size: 12))
                                                                    .foregroundColor(engine.isFavorite(track: track) ? .red : Color.white.opacity(0.4))
                                                            }
                                                            .buttonStyle(PlainButtonStyle())
                                                            
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
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(engine.isDropTargeted ? Color.white.opacity(0.6) : Color.clear, lineWidth: 3)
                )
                .onDrop(of: [.fileURL], isTargeted: $engine.isDropTargeted) { providers in
                    var urls: [URL] = []
                    let group = DispatchGroup()
                    
                    for provider in providers {
                        group.enter()
                        _ = provider.loadObject(ofClass: URL.self) { url, _ in
                            if let url = url {
                                urls.append(url)
                            }
                            group.leave()
                        }
                    }
                    
                    group.notify(queue: .main) {
                        engine.handleDroppedURLs(urls)
                    }
                    return true
                }
            }
        }
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
