import SwiftUI
import AppKit
import AVFoundation
import MediaPlayer
import Combine
import UniformTypeIdentifiers
import CoreMedia

// MARK: - Data Models

enum AccentTheme: String, CaseIterable, Identifiable, Codable {
    case white = "Minimalist White"
    case emerald = "Emerald"
    case sapphire = "Sapphire"
    case crimson = "Crimson"
    case amber = "Amber"
    
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .white: return Color.white
        case .emerald: return Color(red: 0.16, green: 0.80, blue: 0.50)
        case .sapphire: return Color(red: 0.25, green: 0.55, blue: 0.95)
        case .crimson: return Color(red: 0.92, green: 0.25, blue: 0.35)
        case .amber: return Color(red: 0.95, green: 0.65, blue: 0.20)
        }
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable, Codable {
    case dark = "Dark Mode"
    case pitchBlack = "Pitch Black"
    case light = "Light Mode"
    
    var id: String { self.rawValue }
}

struct Track: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let title: String
    let artist: String
    let album: String
    let genre: String
    let year: String
    let duration: TimeInterval
    let artwork: NSImage?
    let formatName: String
    let sampleRate: Double
    let bitrate: Int
    let channelCount: Int
    let fileSizeString: String
    
    var audioBadgeText: String {
        let sr = sampleRate > 0 ? String(format: "%.1fkHz", sampleRate / 1000.0) : "44.1kHz"
        if bitrate > 0 {
            return "\(formatName) • \(sr) • \(bitrate) kbps"
        } else {
            return "\(formatName) • \(sr)"
        }
    }
    
    static func == (lhs: Track, rhs: Track) -> Bool {
        return lhs.id == rhs.id
    }
}

struct TrackStats: Codable {
    var playCount: Int = 0
    var lastPlayedDate: Date? = nil
    var dateAdded: Date = Date()
}

struct AlbumGroup: Identifiable, Equatable {
    var id: String { name }
    let name: String
    let artist: String
    let artwork: NSImage?
    let tracks: [Track]
    
    static func == (lhs: AlbumGroup, rhs: AlbumGroup) -> Bool {
        return lhs.name == rhs.name && lhs.tracks.count == rhs.tracks.count
    }
}

enum NavigationItem: String, CaseIterable, Identifiable {
    case library = "Library"
    case albums = "Albums"
    case artists = "Artists"
    case nowPlaying = "Now Playing"
    case folders = "Folder Mode"
    case favorites = "Favorites"
    case playlists = "Playlists"
    case recentlyAdded = "Recently Added"
    case mostPlayed = "Most Played"
    case recentlyPlayed = "Recently Played"
    case equalizer = "Equalizer"
    case settings = "Settings"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .library: return "music.note"
        case .albums: return "square.grid.2x2.fill"
        case .artists: return "person.2.fill"
        case .nowPlaying: return "play.circle.fill"
        case .folders: return "folder.fill"
        case .favorites: return "heart.fill"
        case .playlists: return "music.note.list"
        case .recentlyAdded: return "clock.badge.fill"
        case .mostPlayed: return "flame.fill"
        case .recentlyPlayed: return "arrow.counterclockwise"
        case .equalizer: return "slider.vertical.3"
        case .settings: return "gearshape.fill"
        }
    }
}

enum SortOption: String, CaseIterable, Identifiable {
    case title = "Title"
    case artist = "Artist"
    case album = "Album"
    case duration = "Duration"
    case genre = "Genre"
    case dateAdded = "Date Added"
    case playCount = "Play Count"
    
    var id: String { self.rawValue }
}

enum CrossfadeDuration: String, CaseIterable, Identifiable, Codable {
    case off = "Off"
    case one = "1 second"
    case two = "2 seconds"
    case three = "3 seconds"
    case five = "5 seconds"
    
    var id: String { self.rawValue }
    
    var seconds: Double {
        switch self {
        case .off: return 0
        case .one: return 1
        case .two: return 2
        case .three: return 3
        case .five: return 5
        }
    }
}

struct UserPlaylist: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var trackPaths: [String]
}

struct ArtistGroup: Identifiable, Equatable {
    var id: String { name }
    let name: String
    let albums: [AlbumGroup]
    let tracks: [Track]
    let artwork: NSImage?
    
    static func == (lhs: ArtistGroup, rhs: ArtistGroup) -> Bool {
        return lhs.name == rhs.name && lhs.tracks.count == rhs.tracks.count
    }
}

enum PlayerAnimationOption: String, CaseIterable, Identifiable, Codable {
    case smoothSpring = "Fluid Spring"
    case vinylSpin = "Vinyl Record Spin"
    case waveSpectrum = "Wave Spectrum Ring"
    case floatingCard = "Floating Glass Card"
    case ambientAura = "Ambient Aura Glow"
    case gentleEase = "Gentle Ease"
    case snappyLinear = "Snappy Fast"
    
    var id: String { self.rawValue }
    
    var animation: Animation {
        switch self {
        case .smoothSpring: return .spring(response: 0.38, dampingFraction: 0.72)
        case .vinylSpin: return .interactiveSpring(response: 0.45, dampingFraction: 0.65)
        case .waveSpectrum: return .spring(response: 0.5, dampingFraction: 0.6)
        case .floatingCard: return .easeInOut(duration: 0.6)
        case .ambientAura: return .easeInOut(duration: 0.8)
        case .gentleEase: return .easeInOut(duration: 0.4)
        case .snappyLinear: return .linear(duration: 0.15)
        }
    }
}

enum VisualizerBarStyle: String, CaseIterable, Identifiable, Codable {
    case verticalBars = "Vertical Bars"
    case sineWaveform = "Continuous Waveform"
    case glowingDots = "Pulsing Dots Matrix"
    case floatingParticles = "Audio Particles"
    case minimalPills = "Minimal Pill Meters"
    case mirrorFrequency = "Mirrored Dual Spectrum"
    case cyberpunkGrid = "Cyberpunk Peak Equalizer"
    case circularOrbit = "Circular Orbit Ring"
    case liquidFlow = "Fluid Liquid Wave"
    case strobeBeat = "Strobe Pulse Meters"
    
    var id: String { self.rawValue }
}

struct SavedLibraryData: Codable {
    var filePaths: [String]
    var favoritePaths: [String]?
    var eqGains: [Float]?
    var accentTheme: AccentTheme?
    var appearanceMode: AppearanceMode?
    var useDynamicArtworkTheme: Bool?
    var playerAnimation: PlayerAnimationOption?
    var visualizerBarStyle: VisualizerBarStyle?
    var userPlaylists: [UserPlaylist]?
    var lastFolderURL: String?
    var windowFrame: [CGFloat]?
    var sidebarWidth: CGFloat?
    var crossfadeDuration: CrossfadeDuration?
    var enableSliceOfLifeTheme: Bool?
    var enableSidebarLiquidGlass: Bool?
    var isSidebarCollapsed: Bool?
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

// MARK: - Playlist Exporter & USB/DAP Sync Engine

class PlaylistSyncManager {
    static let shared = PlaylistSyncManager()
    
    func generateM3UContent(tracks: [Track], isRelative: Bool = false) -> String {
        var lines: [String] = ["#EXTM3U"]
        for track in tracks {
            let duration = Int(track.duration)
            let titleLine = "#EXTINF:\(duration),\(track.artist) - \(track.title)"
            lines.append(titleLine)
            if isRelative {
                lines.append(track.url.lastPathComponent)
            } else {
                lines.append(track.url.path)
            }
        }
        return lines.joined(separator: "\n")
    }
    
    func exportM3UFile(tracks: [Track], defaultName: String) {
        guard !tracks.isEmpty else { return }
        let savePanel = NSSavePanel()
        savePanel.title = "Export M3U Playlist"
        savePanel.prompt = "Export"
        savePanel.nameFieldStringValue = "\(defaultName).m3u8"
        savePanel.allowedContentTypes = [
            UTType(filenameExtension: "m3u8") ?? .plainText,
            UTType(filenameExtension: "m3u") ?? .plainText
        ]
        
        if savePanel.runModal() == .OK, let destinationURL = savePanel.url {
            let content = generateM3UContent(tracks: tracks, isRelative: false)
            try? content.write(to: destinationURL, atomically: true, encoding: .utf8)
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
    @Published var playbackRate: Float = 1.0 {
        didSet {
            if let player = audioPlayer {
                player.enableRate = true
                player.rate = playbackRate
            }
        }
    }
    @Published var pan: Float = 0.0 {
        didSet {
            audioPlayer?.pan = pan
        }
    }
    
    @Published var currentTrack: Track?
    @Published var playlist: [Track] = []
    @Published var favoritePaths: Set<String> = []
    @Published var isShuffled: Bool = false
    @Published var isRepeated: Bool = false
    @Published var visualizerLevels: [CGFloat] = Array(repeating: 0.15, count: 16)
    
    // Up Next Play Queue
    @Published var playQueue: [Track] = []
    @Published var showQueueDrawer: Bool = false
    
    // USB / DAP Direct Sync State
    @Published var isSyncingToUSB: Bool = false
    @Published var syncProgress: Double = 0.0
    @Published var syncStatusText: String = ""
    @Published var showSyncDrawer: Bool = false
    
    // Theme & Appearance State
    @Published var currentAccent: AccentTheme = .white
    @Published var dynamicAccentColor: Color? = nil
    @Published var appearanceMode: AppearanceMode = .dark
    @Published var useDynamicArtworkTheme: Bool = true
    @Published var playerAnimation: PlayerAnimationOption = .smoothSpring
    @Published var visualizerBarStyle: VisualizerBarStyle = .verticalBars
    @Published var enableSliceOfLifeTheme: Bool = false
    @Published var enableSidebarLiquidGlass: Bool = true
    @Published var isSidebarCollapsed: Bool = false
    
    // Folder Mode State
    @Published var selectedFolderURL: URL? = nil
    @Published var folderTracks: [Track] = []
    
    // Playlists & Sorting State
    @Published var userPlaylists: [UserPlaylist] = []
    @Published var activePlaylistId: UUID? = nil
    @Published var currentSort: SortOption = .title
    @Published var newPlaylistName: String = ""
    @Published var showNewPlaylistPrompt: Bool = false
    @Published var selectedAlbum: AlbumGroup? = nil
    @Published var selectedArtist: ArtistGroup? = nil
    
    // Sleep Timer State
    @Published var sleepTimerMinutes: Int = 0 // 0 = off, 15, 30, 45, 60, -1 = end of track
    @Published var sleepTimerRemainingSeconds: Int = 0
    private var sleepTimer: Timer?
    
    // Equalizer State (5 Bands: 60Hz, 230Hz, 910Hz, 3.6kHz, 14kHz)
    @Published var selectedEQPreset: EQPreset = .flat
    @Published var eqGains: [Float] = [0, 0, 0, 0, 0]
    
    // Lyrics & View Toggles
    @Published var currentLyrics: [LyricLine] = []
    @Published var activeLyricIndex: Int? = nil
    @Published var showLyrics: Bool = true
    @Published var inspectingTrack: Track? = nil
    
    // Navigation & UI State
    @Published var selectedNav: NavigationItem = .nowPlaying
    @Published var searchText: String = ""
    @Published var hoveredButtonId: String? = nil
    @Published var hoveredTrackId: UUID? = nil
    @Published var isDropTargeted: Bool = false
    @Published var isMiniPlayer: Bool = false
    
    // Track Stats (Play Count, Last Played, Date Added)
    @Published var trackStats: [String: TrackStats] = [:]
    
    // Crossfade & Gapless Playback
    @Published var crossfadeDuration: CrossfadeDuration = .off
    
    // Resizable Sidebar
    @Published var sidebarWidth: CGFloat = 200
    
    private var audioPlayer: AVAudioPlayer?
    private var crossfadePlayer: AVAudioPlayer?
    private var nextTrackBuffer: AVAudioPlayer?
    private var timer: Timer?
    private var visualizerTimer: Timer?
    private var scrobbleTimer: Timer?
    
    var activeAccentColor: Color {
        if useDynamicArtworkTheme, let sampled = dynamicAccentColor {
            return sampled
        }
        return currentAccent.color
    }
    
    // MARK: - Smart Playlist Computed Properties
    
    var recentlyAddedTracks: [Track] {
        let cutoff = Date().addingTimeInterval(-30 * 24 * 3600) // Last 30 days
        return playlist.filter { track in
            if let stats = trackStats[track.url.path] {
                return stats.dateAdded > cutoff
            }
            return true // If no stats yet, treat as recently added
        }.sorted { a, b in
            let dateA = trackStats[a.url.path]?.dateAdded ?? Date()
            let dateB = trackStats[b.url.path]?.dateAdded ?? Date()
            return dateA > dateB
        }
    }
    
    var mostPlayedTracks: [Track] {
        return playlist.filter { track in
            (trackStats[track.url.path]?.playCount ?? 0) > 0
        }.sorted { a, b in
            (trackStats[a.url.path]?.playCount ?? 0) > (trackStats[b.url.path]?.playCount ?? 0)
        }.prefix(25).map { $0 }
    }
    
    var recentlyPlayedTracks: [Track] {
        return playlist.filter { track in
            trackStats[track.url.path]?.lastPlayedDate != nil
        }.sorted { a, b in
            let dateA = trackStats[a.url.path]?.lastPlayedDate ?? Date.distantPast
            let dateB = trackStats[b.url.path]?.lastPlayedDate ?? Date.distantPast
            return dateA > dateB
        }.prefix(20).map { $0 }
    }
    
    var albumsList: [AlbumGroup] {
        let grouped = Dictionary(grouping: playlist, by: { $0.album })
        return grouped.map { (albumName, tracks) in
            AlbumGroup(
                name: albumName,
                artist: tracks.first?.artist ?? "Unknown Artist",
                artwork: tracks.first(where: { $0.artwork != nil })?.artwork,
                tracks: tracks
            )
        }.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }
    
    var artistsList: [ArtistGroup] {
        let grouped = Dictionary(grouping: playlist, by: { $0.artist })
        return grouped.map { (artistName, tracks) in
            let albumDict = Dictionary(grouping: tracks, by: { $0.album })
            let albums = albumDict.map { (albumName, albumTracks) in
                AlbumGroup(
                    name: albumName,
                    artist: artistName,
                    artwork: albumTracks.first(where: { $0.artwork != nil })?.artwork,
                    tracks: albumTracks
                )
            }.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
            
            return ArtistGroup(
                name: artistName,
                albums: albums,
                tracks: tracks,
                artwork: tracks.first(where: { $0.artwork != nil })?.artwork
            )
        }.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }
    
    override init() {
        super.init()
        setupRemoteCommandCenter()
        loadLibrary()
    }
    
    // MARK: - Dynamic Color Extractor from Album Cover Art
    
    func extractDominantColor(from image: NSImage) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let totalBytes = bytesPerRow * height
        
        var rawData = [UInt8](repeating: 0, count: totalBytes)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var rSum: Double = 0
        var gSum: Double = 0
        var bSum: Double = 0
        var sampleCount: Double = 0
        
        let step = max(1, (width * height) / 200) // Sample 200 pixels
        for i in stride(from: 0, to: width * height, by: step) {
            let offset = i * 4
            if offset + 3 < rawData.count {
                let r = Double(rawData[offset]) / 255.0
                let g = Double(rawData[offset + 1]) / 255.0
                let b = Double(rawData[offset + 2]) / 255.0
                
                // Exclude near-black, near-white, or dull grays
                let maxC = max(r, max(g, b))
                let minC = min(r, min(g, b))
                let saturation = maxC == 0 ? 0 : (maxC - minC) / maxC
                let brightness = maxC
                
                if saturation > 0.15 && brightness > 0.2 && brightness < 0.95 {
                    rSum += r
                    gSum += g
                    bSum += b
                    sampleCount += 1
                }
            }
        }
        
        if sampleCount > 0 {
            let finalR = rSum / sampleCount
            let finalG = gSum / sampleCount
            let finalB = bSum / sampleCount
            DispatchQueue.main.async {
                self.dynamicAccentColor = Color(red: finalR, green: finalG, blue: finalB)
            }
        }
    }
    
    // MARK: - Play Queue Management
    
    func playNext(track: Track) {
        playQueue.insert(track, at: 0)
    }
    
    func addToQueue(track: Track) {
        playQueue.append(track)
    }
    
    func removeFromQueue(at index: Int) {
        guard index >= 0 && index < playQueue.count else { return }
        playQueue.remove(at: index)
    }
    
    func clearQueue() {
        playQueue.removeAll()
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
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? Double(playbackRate) : 0.0
        ]
        
        if let artwork = track.artwork {
            let mpArtwork = MPMediaItemArtwork(boundsSize: artwork.size) { _ in artwork }
            info[MPMediaItemPropertyArtwork] = mpArtwork
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        
        // Update Dock Icon Progress Indicator Badge
        DispatchQueue.main.async {
            if self.isPlaying && self.duration > 0 {
                let progressPercent = Int((self.currentTime / self.duration) * 100)
                NSApp.dockTile.badgeLabel = "\(progressPercent)%"
            } else {
                NSApp.dockTile.badgeLabel = nil
            }
            NSApp.dockTile.display()
        }
    }
    
    // MARK: - Playback Logic
    
    func loadAndPlay(track: Track) {
        currentTrack = track
        if let artwork = track.artwork {
            extractDominantColor(from: artwork)
        } else {
            dynamicAccentColor = nil
        }
        
        // Update last played date
        let path = track.url.path
        if trackStats[path] == nil {
            trackStats[path] = TrackStats(playCount: 0, lastPlayedDate: Date(), dateAdded: Date())
        } else {
            trackStats[path]?.lastPlayedDate = Date()
        }
        saveTrackStats()
        
        // Crossfade: If crossfade is enabled and a track is currently playing, fade out old player
        if crossfadeDuration.seconds > 0, let oldPlayer = audioPlayer, oldPlayer.isPlaying {
            crossfadePlayer = oldPlayer
            let fadeDuration = crossfadeDuration.seconds
            let steps = 20
            let stepInterval = fadeDuration / Double(steps)
            let volumeStep = oldPlayer.volume / Float(steps)
            
            for i in 1...steps {
                DispatchQueue.main.asyncAfter(deadline: .now() + stepInterval * Double(i)) { [weak self] in
                    self?.crossfadePlayer?.volume = max(0, oldPlayer.volume - volumeStep * Float(i))
                    if i == steps {
                        self?.crossfadePlayer?.stop()
                        self?.crossfadePlayer = nil
                    }
                }
            }
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: track.url)
            audioPlayer?.delegate = self
            audioPlayer?.volume = crossfadeDuration.seconds > 0 ? 0 : volume
            audioPlayer?.enableRate = true
            audioPlayer?.rate = playbackRate
            audioPlayer?.pan = pan
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            // Fade in if crossfade is active
            if crossfadeDuration.seconds > 0 {
                let fadeDuration = crossfadeDuration.seconds
                let steps = 20
                let stepInterval = fadeDuration / Double(steps)
                let volumeStep = volume / Float(steps)
                for i in 1...steps {
                    DispatchQueue.main.asyncAfter(deadline: .now() + stepInterval * Double(i)) { [weak self] in
                        self?.audioPlayer?.volume = min(self?.volume ?? 0.8, volumeStep * Float(i))
                    }
                }
            }
            
            isPlaying = true
            duration = audioPlayer?.duration ?? track.duration
            currentTime = 0
            
            loadLyrics(for: track)
            startTimers()
            updateNowPlayingInfo()
            
            // Start scrobble timer: increment play count after 30 seconds
            scrobbleTimer?.invalidate()
            scrobbleTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                if self.trackStats[path] != nil {
                    self.trackStats[path]!.playCount += 1
                } else {
                    self.trackStats[path] = TrackStats(playCount: 1, lastPlayedDate: Date(), dateAdded: Date())
                }
                self.saveTrackStats()
            }
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
        // Priority 1: Up Next Play Queue
        if !playQueue.isEmpty {
            let next = playQueue.removeFirst()
            loadAndPlay(track: next)
            return
        }
        
        let activeList = currentTrackList()
        guard !activeList.isEmpty else { return }
        if isShuffled {
            if let randomTrack = activeList.randomElement() {
                loadAndPlay(track: randomTrack)
            }
        } else if let current = currentTrack, let index = activeList.firstIndex(of: current) {
            let nextIndex = (index + 1) % activeList.count
            loadAndPlay(track: activeList[nextIndex])
        } else {
            loadAndPlay(track: activeList[0])
        }
    }
    
    func previousTrack() {
        let activeList = currentTrackList()
        guard !activeList.isEmpty else { return }
        if currentTime > 3.0 {
            seek(to: 0)
            return
        }
        if let current = currentTrack, let index = activeList.firstIndex(of: current) {
            let prevIndex = (index - 1 + activeList.count) % activeList.count
            loadAndPlay(track: activeList[prevIndex])
        } else {
            loadAndPlay(track: activeList[0])
        }
    }
    
    private func currentTrackList() -> [Track] {
        if selectedNav == .folders && !folderTracks.isEmpty {
            return folderTracks
        } else if selectedNav == .favorites {
            return playlist.filter { isFavorite(track: $0) }
        } else if selectedNav == .playlists, let id = activePlaylistId, let pl = userPlaylists.first(where: { $0.id == id }) {
            let paths = Set(pl.trackPaths)
            return playlist.filter { paths.contains($0.url.path) }
        } else if selectedNav == .recentlyAdded {
            return recentlyAddedTracks
        } else if selectedNav == .mostPlayed {
            return mostPlayedTracks
        } else if selectedNav == .recentlyPlayed {
            return recentlyPlayedTracks
        }
        return playlist
    }
    
    // MARK: - Folder Mode & Select Folder Action
    
    func selectFolderToPlay() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Music Folder"
        
        if panel.runModal() == .OK, let folderURL = panel.url {
            selectedFolderURL = folderURL
            let scanned = scanDirectory(folderURL)
            folderTracks = scanned
            
            // Auto-range & merge all scanned folder tracks into main library playlist
            let uniqueTracks = scanned.filter { track in
                !self.playlist.contains(where: { $0.url == track.url })
            }
            self.playlist.append(contentsOf: uniqueTracks)
            
            selectedNav = .folders
            saveLibrary()
            if let first = scanned.first {
                loadAndPlay(track: first)
            }
        }
    }
    
    // MARK: - Custom Playlist Management
    
    func createPlaylist(name: String) {
        let cleanName = name.trimmingCharacters(in: .whitespaces)
        guard !cleanName.isEmpty else { return }
        let newPL = UserPlaylist(name: cleanName, trackPaths: [])
        userPlaylists.append(newPL)
        activePlaylistId = newPL.id
        saveLibrary()
    }
    
    func deletePlaylist(id: UUID) {
        userPlaylists.removeAll(where: { $0.id == id })
        if activePlaylistId == id {
            activePlaylistId = userPlaylists.first?.id
        }
        saveLibrary()
    }
    
    func addTrackToPlaylist(track: Track, playlistId: UUID) {
        if let index = userPlaylists.firstIndex(where: { $0.id == playlistId }) {
            if !userPlaylists[index].trackPaths.contains(track.url.path) {
                userPlaylists[index].trackPaths.append(track.url.path)
                saveLibrary()
            }
        }
    }
    
    func removeTrackFromPlaylist(track: Track, playlistId: UUID) {
        if let index = userPlaylists.firstIndex(where: { $0.id == playlistId }) {
            userPlaylists[index].trackPaths.removeAll(where: { $0 == track.url.path })
            saveLibrary()
        }
    }
    
    // MARK: - USB / DAP Direct Sync & Playlist Exporter
    
    func activePlaylistTitle() -> String {
        if selectedNav == .playlists, let id = activePlaylistId, let pl = userPlaylists.first(where: { $0.id == id }) {
            return pl.name
        }
        return selectedNav.rawValue
    }
    
    func exportActivePlaylistM3U() {
        let tracks = currentTrackList()
        let name = activePlaylistTitle()
        PlaylistSyncManager.shared.exportM3UFile(tracks: tracks, defaultName: name)
    }
    
    func syncActivePlaylistToUSB() {
        let tracks = currentTrackList()
        guard !tracks.isEmpty else { return }
        let name = activePlaylistTitle()
        
        let openPanel = NSOpenPanel()
        openPanel.title = "Select USB Drive or DAP Destination Folder"
        openPanel.prompt = "Sync Playlist Here"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK, let targetURL = openPanel.url {
            startUSBSync(tracks: tracks, playlistName: name, targetURL: targetURL)
        }
    }
    
    private func startUSBSync(tracks: [Track], playlistName: String, targetURL: URL) {
        let safeName = playlistName.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "_")
        let destinationFolder = targetURL.appendingPathComponent(safeName.isEmpty ? "San_Playlist" : safeName, isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(at: destinationFolder, withIntermediateDirectories: true)
        } catch {
            print("Failed to create target USB directory: \(error.localizedDescription)")
            return
        }
        
        isSyncingToUSB = true
        syncProgress = 0.0
        syncStatusText = "Preparing USB Sync..."
        showSyncDrawer = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let total = tracks.count
            var copiedCount = 0
            var copiedTracks: [Track] = []
            
            for (index, track) in tracks.enumerated() {
                guard self?.isSyncingToUSB == true else { break }
                
                let fileName = String(format: "%02d - %@", index + 1, track.url.lastPathComponent)
                let destFileURL = destinationFolder.appendingPathComponent(fileName)
                
                DispatchQueue.main.async {
                    self?.syncStatusText = "Copying (\(index + 1)/\(total)): \(track.title)"
                    self?.syncProgress = Double(index) / Double(total)
                }
                
                if FileManager.default.fileExists(atPath: destFileURL.path) {
                    try? FileManager.default.removeItem(at: destFileURL)
                }
                
                do {
                    try FileManager.default.copyItem(at: track.url, to: destFileURL)
                    copiedCount += 1
                    copiedTracks.append(track)
                } catch {
                    print("Error copying track \(track.title): \(error.localizedDescription)")
                }
            }
            
            // Create relative .m3u8 playlist on the USB drive
            if let manager = self {
                let m3uContent = PlaylistSyncManager.shared.generateM3UContent(tracks: copiedTracks, isRelative: true)
                let m3uPath = destinationFolder.appendingPathComponent("\(safeName).m3u8")
                try? m3uContent.write(to: m3uPath, atomically: true, encoding: .utf8)
            }
            
            DispatchQueue.main.async {
                self?.syncProgress = 1.0
                self?.syncStatusText = "Completed! Synced \(copiedCount) of \(total) tracks to USB/DAP."
                self?.isSyncingToUSB = false
            }
        }
    }
    
    func cancelUSBSync() {
        isSyncingToUSB = false
        showSyncDrawer = false
    }
    
    // MARK: - Sleep Timer Engine
    
    func setSleepTimer(minutes: Int) {
        sleepTimerMinutes = minutes
        sleepTimer?.invalidate()
        sleepTimer = nil
        
        if minutes > 0 {
            sleepTimerRemainingSeconds = minutes * 60
            sleepTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                if self.sleepTimerRemainingSeconds > 0 {
                    self.sleepTimerRemainingSeconds -= 1
                } else {
                    self.togglePlay()
                    self.setSleepTimer(minutes: 0)
                }
            }
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
    
    // MARK: - Remove Tracks from Library
    
    func removeTrack(track: Track) {
        let path = track.url.path
        playlist.removeAll(where: { $0.url.path == path })
        favoritePaths.remove(path)
        trackStats.removeValue(forKey: path)
        for i in 0..<userPlaylists.count {
            userPlaylists[i].trackPaths.removeAll(where: { $0 == path })
        }
        if currentTrack?.url.path == path {
            currentTrack = nil
            audioPlayer?.stop()
            isPlaying = false
        }
        saveLibrary()
        saveTrackStats()
    }
    
    func removeTracksFromLibrary(tracks: [Track]) {
        for track in tracks {
            removeTrack(track: track)
        }
    }
    
    func getPlayCount(for track: Track) -> Int {
        return trackStats[track.url.path]?.playCount ?? 0
    }
    
    func getDateAdded(for track: Track) -> Date {
        return trackStats[track.url.path]?.dateAdded ?? Date()
    }
    
    // MARK: - Equalizer & Theme Controls
    
    func setAccentTheme(_ theme: AccentTheme) {
        currentAccent = theme
        saveLibrary()
    }
    
    func applyEQPreset(_ preset: EQPreset) {
        selectedEQPreset = preset
        eqGains = preset.gains
        saveLibrary()
    }
    
    // MARK: - Synced Lyrics Engine (.lrc & Embedded)
    
    func toggleLyricsDisplay() {
        showLyrics.toggle()
        if showLyrics, let track = currentTrack {
            loadLyrics(for: track)
        }
    }
    
    private func loadLyrics(for track: Track) {
        currentLyrics = []
        activeLyricIndex = nil
        
        // 1. Comprehensive Local Folder Scan (.lrc & .txt sidecar files)
        if let folderLyricContent = scanLocalFolderForLyrics(track: track) {
            let parsed = parseLRC(folderLyricContent)
            if !parsed.isEmpty {
                currentLyrics = parsed
                return
            } else {
                let lines = folderLyricContent.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                if !lines.isEmpty {
                    currentLyrics = lines.enumerated().map { index, line in
                        LyricLine(time: TimeInterval(index * 4), text: line)
                    }
                    return
                }
            }
        }
        
        // 2. Embedded metadata lyrics check (FLAC Vorbis comments LYRICS/UNSYNCEDLYRICS/SYNCEDLYRICS or MP3 ID3 USLT)
        let asset = AVURLAsset(url: track.url)
        var rawEmbeddedLyrics: String? = nil
        
        // Check asset.metadata directly
        for item in asset.metadata + asset.commonMetadata {
            let keyStr = ((item.commonKey?.rawValue ?? "") + (item.identifier?.rawValue ?? "") + (item.key?.description ?? "")).lowercased()
            if keyStr.contains("lyrics") || keyStr.contains("uslt") || keyStr.contains("unsyncedlyrics") || keyStr.contains("syncedlyrics") {
                if let val = item.value as? String, !val.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    rawEmbeddedLyrics = val
                    break
                }
            }
        }
        
        // Check availableMetadataFormats if not found yet
        if rawEmbeddedLyrics == nil {
            for format in asset.availableMetadataFormats {
                for item in asset.metadata(forFormat: format) {
                    let keyStr = ((item.commonKey?.rawValue ?? "") + (item.identifier?.rawValue ?? "") + (item.key?.description ?? "")).lowercased()
                    if keyStr.contains("lyrics") || keyStr.contains("uslt") || keyStr.contains("unsyncedlyrics") || keyStr.contains("syncedlyrics") {
                        if let val = item.value as? String, !val.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            rawEmbeddedLyrics = val
                            break
                        }
                    }
                }
                if rawEmbeddedLyrics != nil { break }
            }
        }
        
        // 3. Fallback: Scan raw file stream for FLAC Vorbis comments (LYRICS=, UNSYNCEDLYRICS=, etc.)
        if rawEmbeddedLyrics == nil {
            rawEmbeddedLyrics = extractLyricsFromRawFile(track.url)
        }
        
        if let text = rawEmbeddedLyrics {
            let parsed = parseLRC(text)
            if !parsed.isEmpty {
                currentLyrics = parsed
            } else {
                let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                currentLyrics = lines.enumerated().map { index, line in
                    LyricLine(time: TimeInterval(index * 4), text: line)
                }
            }
        }
    }
    
    private func scanLocalFolderForLyrics(track: Track) -> String? {
        let folderURL = track.url.deletingLastPathComponent()
        let baseName = track.url.deletingPathExtension().lastPathComponent
        let cleanTitle = track.title.lowercased()
        
        let candidateNames = [
            "\(baseName).lrc",
            "\(baseName).txt",
            "\(track.artist) - \(track.title).lrc",
            "\(track.artist) - \(track.title).txt",
            "\(track.title).lrc",
            "\(track.title).txt"
        ]
        
        for name in candidateNames {
            let candidateURL = folderURL.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: candidateURL.path),
               let content = try? String(contentsOf: candidateURL, encoding: .utf8),
               !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return content
            }
        }
        
        // Scan folder for any .lrc or .txt file matching track title
        if let enumerator = FileManager.default.enumerator(at: folderURL, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants]) {
            for case let fileURL as URL in enumerator {
                let ext = fileURL.pathExtension.lowercased()
                if ext == "lrc" || ext == "txt" {
                    let name = fileURL.deletingPathExtension().lastPathComponent.lowercased()
                    if !cleanTitle.isEmpty && (name.contains(cleanTitle) || cleanTitle.contains(name)) {
                        if let content = try? String(contentsOf: fileURL, encoding: .utf8),
                           !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            return content
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    private func extractLyricsFromRawFile(_ url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        
        // Read first 1 MB of file (where FLAC metadata Vorbis comments and MP3 ID3 headers reside)
        guard let data = try? handle.read(upToCount: 1024 * 1024) else { return nil }
        
        let targetKeys = ["LYRICS=", "UNSYNCEDLYRICS=", "SYNCEDLYRICS=", "lyrics=", "USLT"]
        
        for key in targetKeys {
            guard let keyData = key.data(using: .utf8) else { continue }
            if let range = data.range(of: keyData) {
                let startOffset = range.upperBound
                let remaining = data.subdata(in: startOffset..<min(data.count, startOffset + 32768))
                
                var lyricBytes: [UInt8] = []
                for byte in remaining {
                    // Vorbis comment strings end at null byte or non-text control byte (except \n \r \t)
                    if byte == 0 || (byte < 32 && byte != 10 && byte != 13 && byte != 9) {
                        if lyricBytes.count > 10 { break }
                    } else {
                        lyricBytes.append(byte)
                    }
                }
                
                if let str = String(bytes: lyricBytes, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !str.isEmpty {
                    return str
                }
            }
        }
        return nil
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
    
    // MARK: - File Import & Metadata Extraction
    
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
        var genre = ""
        var year = ""
        var artworkImage: NSImage?
        
        let formatName = url.pathExtension.uppercased()
        var sampleRate: Double = 44100
        var bitrate: Int = 320
        var channelCount: Int = 2
        
        let seconds = CMTimeGetSeconds(asset.duration)
        let trackDuration = seconds.isNaN || seconds <= 0 ? 180.0 : seconds
        
        // Calculate file size string
        var sizeString = "Unknown Size"
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let bytes = attrs[.size] as? Int64 {
            let mb = Double(bytes) / 1024.0 / 1024.0
            sizeString = String(format: "%.1f MB", mb)
        }
        
        // Inspect Audio Stream Details
        let audioTracks = asset.tracks(withMediaType: .audio)
        if let audioTrack = audioTracks.first {
            let rate = audioTrack.estimatedDataRate
            if rate > 0 {
                bitrate = Int(rate / 1000.0)
            }
            
            for desc in audioTrack.formatDescriptions {
                let formatDesc = desc as! CMAudioFormatDescription
                if let basicDesc = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc) {
                    if basicDesc.pointee.mSampleRate > 0 {
                        sampleRate = basicDesc.pointee.mSampleRate
                    }
                    if basicDesc.pointee.mChannelsPerFrame > 0 {
                        channelCount = Int(basicDesc.pointee.mChannelsPerFrame)
                    }
                }
            }
        }
        
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
                    case "type":
                        if let val = item.value as? String, !val.isEmpty { genre = val }
                    case "creationDate":
                        if let val = item.value as? String, !val.isEmpty { year = String(val.prefix(4)) }
                    default:
                        break
                    }
                }
                
                // Also check for ID3/iTunes specific genre & year tags
                if let identifier = item.identifier?.rawValue {
                    if identifier.contains("TCON") || identifier.contains("genre") {
                        if let val = item.value as? String, !val.isEmpty, genre.isEmpty { genre = val }
                    }
                    if identifier.contains("TDRC") || identifier.contains("TYER") || identifier.contains("year") {
                        if let val = item.value as? String, !val.isEmpty, year.isEmpty { year = String(val.prefix(4)) }
                    }
                }
            }
        }
        
        // Smart Folder Structure & Filename Auto-Detection for Artist & Album
        let parentDirName = url.deletingLastPathComponent().lastPathComponent
        let grandparentDirName = url.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent
        
        // 1. Album Auto-Detection from Parent Folder Name
        if album == "Unknown Album" || album.trimmingCharacters(in: .whitespaces).isEmpty {
            let ignoredNames: Set<String> = ["/", "Music", "Downloads", "Desktop", "Documents", "san", "untitled folder", "untitled"]
            if !parentDirName.isEmpty && !ignoredNames.contains(parentDirName) {
                album = parentDirName
            }
        }
        
        // 2. Artist Auto-Detection from Filename ("Artist - Title.mp3") or Grandparent Folder
        if artist == "Unknown Artist" || artist.trimmingCharacters(in: .whitespaces).isEmpty {
            let fileName = url.deletingPathExtension().lastPathComponent
            if fileName.contains(" - ") {
                let parts = fileName.components(separatedBy: " - ")
                if parts.count >= 2 {
                    let potentialArtist = parts[0].trimmingCharacters(in: .whitespaces)
                    let potentialTitle = parts[1...].joined(separator: " - ").trimmingCharacters(in: .whitespaces)
                    if !potentialArtist.isEmpty && !potentialTitle.isEmpty {
                        artist = potentialArtist
                        if title == fileName {
                            title = potentialTitle
                        }
                    }
                }
            } else if fileName.contains(" – ") {
                let parts = fileName.components(separatedBy: " – ")
                if parts.count >= 2 {
                    let potentialArtist = parts[0].trimmingCharacters(in: .whitespaces)
                    let potentialTitle = parts[1...].joined(separator: " – ").trimmingCharacters(in: .whitespaces)
                    if !potentialArtist.isEmpty && !potentialTitle.isEmpty {
                        artist = potentialArtist
                        if title == fileName {
                            title = potentialTitle
                        }
                    }
                }
            }
            
            // Grandparent Folder Fallback if still unknown
            let ignoredGrandparents: Set<String> = ["/", "Users", "Music", "Downloads", "Desktop", "Documents", "san", "untitled folder"]
            if artist == "Unknown Artist" && !grandparentDirName.isEmpty && !ignoredGrandparents.contains(grandparentDirName) {
                artist = grandparentDirName
            }
        }
        
        // 1. Try Common Artwork items
        let commonArtwork = AVMetadataItem.metadataItems(from: asset.commonMetadata, withKey: AVMetadataKey.commonKeyArtwork, keySpace: .common)
        if let firstArt = commonArtwork.first, let data = firstArt.value as? Data, let img = NSImage(data: data) {
            artworkImage = img
        }
        
        // 2. Try inspecting all metadata format items for APIC / covr / raw picture data
        if artworkImage == nil {
            for format in formats {
                for item in asset.metadata(forFormat: format) {
                    let keyStr = (item.commonKey?.rawValue ?? "") + (item.identifier?.rawValue ?? "") + (item.key?.description ?? "")
                    if keyStr.contains("APIC") || keyStr.contains("covr") || keyStr.contains("artwork") || keyStr.contains("PIC") {
                        if let data = item.value as? Data, let img = NSImage(data: data) {
                            artworkImage = img
                            break
                        }
                    } else if artworkImage == nil, let data = item.value as? Data, data.count > 1024, let img = NSImage(data: data) {
                        artworkImage = img
                    }
                }
                if artworkImage != nil { break }
            }
        }
        
        // 3. Local Folder Cover Art Fallback (cover.jpg, folder.jpg, album.jpg, etc.)
        if artworkImage == nil {
            let folderURL = url.deletingLastPathComponent()
            let candidates = ["cover.jpg", "cover.png", "folder.jpg", "folder.png", "album.jpg", "album.png", "art.jpg", "art.png", "front.jpg", "front.png"]
            for candidate in candidates {
                let candidateURL = folderURL.appendingPathComponent(candidate)
                if FileManager.default.fileExists(atPath: candidateURL.path), let img = NSImage(contentsOf: candidateURL) {
                    artworkImage = img
                    break
                }
            }
        }
        
        // Register date added in track stats if not already present
        if trackStats[url.path] == nil {
            trackStats[url.path] = TrackStats(playCount: 0, lastPlayedDate: nil, dateAdded: Date())
        }
        
        return Track(
            url: url,
            title: title,
            artist: artist,
            album: album,
            genre: genre,
            year: year,
            duration: trackDuration,
            artwork: artworkImage,
            formatName: formatName,
            sampleRate: sampleRate,
            bitrate: bitrate,
            channelCount: channelCount,
            fileSizeString: sizeString
        )
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
        let savedData = SavedLibraryData(
            filePaths: paths,
            favoritePaths: Array(favoritePaths),
            eqGains: eqGains,
            accentTheme: currentAccent,
            appearanceMode: appearanceMode,
            useDynamicArtworkTheme: useDynamicArtworkTheme,
            playerAnimation: playerAnimation,
            visualizerBarStyle: visualizerBarStyle,
            userPlaylists: userPlaylists,
            lastFolderURL: selectedFolderURL?.path,
            sidebarWidth: sidebarWidth,
            crossfadeDuration: crossfadeDuration,
            enableSliceOfLifeTheme: enableSliceOfLifeTheme,
            enableSidebarLiquidGlass: enableSidebarLiquidGlass,
            isSidebarCollapsed: isSidebarCollapsed
        )
        do {
            let json = try JSONEncoder().encode(savedData)
            try json.write(to: libraryStorageURL)
        } catch {
            print("Failed to save library: \(error.localizedDescription)")
        }
    }
    
    func loadLibrary() {
        loadTrackStats()
        let url = libraryStorageURL
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let savedData = try JSONDecoder().decode(SavedLibraryData.self, from: data)
            
            if let theme = savedData.accentTheme {
                self.currentAccent = theme
            }
            if let mode = savedData.appearanceMode {
                self.appearanceMode = mode
            }
            if let dyn = savedData.useDynamicArtworkTheme {
                self.useDynamicArtworkTheme = dyn
            }
            if let sol = savedData.enableSliceOfLifeTheme {
                self.enableSliceOfLifeTheme = sol
            }
            if let sideGlass = savedData.enableSidebarLiquidGlass {
                self.enableSidebarLiquidGlass = sideGlass
            }
            if let col = savedData.isSidebarCollapsed {
                self.isSidebarCollapsed = col
            }
            if let anim = savedData.playerAnimation {
                self.playerAnimation = anim
            }
            if let visStyle = savedData.visualizerBarStyle {
                self.visualizerBarStyle = visStyle
            }
            if let favs = savedData.favoritePaths {
                self.favoritePaths = Set(favs)
            }
            if let gains = savedData.eqGains, gains.count == 5 {
                self.eqGains = gains
            }
            if let pls = savedData.userPlaylists {
                self.userPlaylists = pls
            }
            if let lastFolder = savedData.lastFolderURL {
                let folderURL = URL(fileURLWithPath: lastFolder)
                if FileManager.default.fileExists(atPath: lastFolder) {
                    self.selectedFolderURL = folderURL
                    self.folderTracks = scanDirectory(folderURL)
                }
            }
            if let sw = savedData.sidebarWidth {
                self.sidebarWidth = sw
            }
            if let cf = savedData.crossfadeDuration {
                self.crossfadeDuration = cf
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
    
    // MARK: - Track Stats Persistence (stats.json)
    
    private var statsStorageURL: URL {
        let fileManager = FileManager.default
        let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let sanDir = appSupportDir.appendingPathComponent("San", isDirectory: true)
        try? fileManager.createDirectory(at: sanDir, withIntermediateDirectories: true)
        return sanDir.appendingPathComponent("stats.json")
    }
    
    func saveTrackStats() {
        do {
            let json = try JSONEncoder().encode(trackStats)
            try json.write(to: statsStorageURL)
        } catch {
            print("Failed to save track stats: \(error.localizedDescription)")
        }
    }
    
    func loadTrackStats() {
        let url = statsStorageURL
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            self.trackStats = try JSONDecoder().decode([String: TrackStats].self, from: data)
        } catch {
            print("Failed to load track stats: \(error.localizedDescription)")
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
            if self.sleepTimerMinutes == -1 {
                self.isPlaying = false
                self.setSleepTimer(minutes: 0)
            } else if self.isRepeated, let current = self.currentTrack {
                self.loadAndPlay(track: current)
            } else {
                self.nextTrack()
            }
        }
    }
}

// MARK: - AppKit Visual Effect Blur View (Liquid Glass)

struct NSVisualEffectBlurView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .withinWindow
    var state: NSVisualEffectView.State = .active
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

// MARK: - Dynamic Appearance UI System

struct UniformDesign {
    static func bgMain(mode: AppearanceMode) -> Color {
        switch mode {
        case .dark: return Color(red: 0.08, green: 0.08, blue: 0.09)
        case .pitchBlack: return Color.black
        case .light: return Color(red: 0.95, green: 0.95, blue: 0.97)
        }
    }
    
    static func bgSidebar(mode: AppearanceMode) -> Color {
        switch mode {
        case .dark: return Color(red: 0.10, green: 0.10, blue: 0.11)
        case .pitchBlack: return Color(red: 0.03, green: 0.03, blue: 0.04)
        case .light: return Color(red: 0.91, green: 0.91, blue: 0.94)
        }
    }
    
    static func bgCard(mode: AppearanceMode) -> Color {
        switch mode {
        case .dark: return Color(red: 0.13, green: 0.13, blue: 0.14)
        case .pitchBlack: return Color(red: 0.06, green: 0.06, blue: 0.07)
        case .light: return Color.white
        }
    }
    
    static func bgBottomBar(mode: AppearanceMode) -> Color {
        switch mode {
        case .dark: return Color(red: 0.11, green: 0.11, blue: 0.12)
        case .pitchBlack: return Color(red: 0.04, green: 0.04, blue: 0.05)
        case .light: return Color(red: 0.93, green: 0.93, blue: 0.96)
        }
    }
    
    static func borderSubtle(mode: AppearanceMode) -> Color {
        switch mode {
        case .dark, .pitchBlack: return Color.white.opacity(0.07)
        case .light: return Color.black.opacity(0.08)
        }
    }
    
    static func activeHighlight(mode: AppearanceMode) -> Color {
        switch mode {
        case .dark, .pitchBlack: return Color.white.opacity(0.12)
        case .light: return Color.black.opacity(0.07)
        }
    }
    
    static func hoverHighlight(mode: AppearanceMode) -> Color {
        switch mode {
        case .dark, .pitchBlack: return Color.white.opacity(0.05)
        case .light: return Color.black.opacity(0.04)
        }
    }
    
    static func textPrimary(mode: AppearanceMode) -> Color {
        switch mode {
        case .dark, .pitchBlack: return Color.white
        case .light: return Color(red: 0.10, green: 0.10, blue: 0.12)
        }
    }
    
    static func textSecondary(mode: AppearanceMode) -> Color {
        switch mode {
        case .dark, .pitchBlack: return Color.white.opacity(0.65)
        case .light: return Color.black.opacity(0.60)
        }
    }
    
    static func textMuted(mode: AppearanceMode) -> Color {
        switch mode {
        case .dark, .pitchBlack: return Color.white.opacity(0.40)
        case .light: return Color.black.opacity(0.38)
        }
    }
}

struct ModernCard<Content: View>: View {
    var cornerRadius: CGFloat = 14
    var mode: AppearanceMode = .dark
    @ViewBuilder var content: Content
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(UniformDesign.bgCard(mode: mode))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(UniformDesign.borderSubtle(mode: mode), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Slice of Life Anime Mascot Header & Background Theme

func loadWaifuAsset(_ name: String) -> NSImage? {
    let localPath = FileManager.default.currentDirectoryPath + "/assets/\(name).png"
    if let img = NSImage(contentsOfFile: localPath) {
        return img
    }
    if let bundlePath = Bundle.main.path(forResource: name, ofType: "png", inDirectory: "assets"),
       let img = NSImage(contentsOfFile: bundlePath) {
        return img
    }
    if let bundlePath = Bundle.main.path(forResource: name, ofType: "png"),
       let img = NSImage(contentsOfFile: bundlePath) {
        return img
    }
    return nil
}

struct SliceOfLifeMascotHeaderView: View {
    @ObservedObject var engine: AudioEngine
    
    var body: some View {
        HStack(spacing: 8) {
            Text("SAN")
                .font(.system(size: 20, weight: .bold, design: .default))
                .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                .tracking(3.5)
            
            Text("三")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(engine.activeAccentColor)
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 6)
    }
}

struct SliceOfLifeBackgroundView: View {
    @ObservedObject var engine: AudioEngine
    
    var bgImage: NSImage? {
        loadWaifuAsset("waifu2")
    }
    
    var body: some View {
        ZStack {
            // Soft Cozy Base Background
            UniformDesign.bgMain(mode: engine.appearanceMode)
                .ignoresSafeArea()
            
            // Waifu2 Wide Shot Anime Background Wallpaper
            if let nsImg = bgImage {
                Image(nsImage: nsImg)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(engine.appearanceMode == .light ? 0.28 : 0.42)
                    .ignoresSafeArea()
            }
            
            // Dynamic Accent Ambient Glow Overlay
            RadialGradient(
                colors: [
                    engine.activeAccentColor.opacity(0.18),
                    Color.purple.opacity(0.10),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 50,
                endRadius: 600
            )
            .ignoresSafeArea()
        }
    }
}

struct ModernButton: View {
    let buttonId: String
    let icon: String
    var size: CGFloat = 36
    var iconSize: CGFloat = 15
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
                        .fill(engine.activeAccentColor)
                        .frame(width: size, height: size)
                    Image(systemName: icon)
                        .font(.system(size: iconSize, weight: .bold))
                        .foregroundColor(.black)
                } else {
                    Circle()
                        .fill(active ? engine.activeAccentColor.opacity(0.25) : (isHovered ? Color.white.opacity(0.1) : Color.white.opacity(0.04)))
                        .frame(width: size, height: size)
                        .overlay(
                            Circle()
                                .stroke(active ? engine.activeAccentColor.opacity(0.5) : UniformDesign.borderSubtle(mode: engine.appearanceMode), lineWidth: 1)
                        )
                    Image(systemName: icon)
                        .font(.system(size: iconSize, weight: .medium))
                        .foregroundColor(active ? engine.activeAccentColor : UniformDesign.textSecondary(mode: engine.appearanceMode))
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
    var size: CGFloat = 160
    var isPlaying: Bool = false
    var accentColor: Color = .white
    var animationOption: PlayerAnimationOption = .smoothSpring
    
    var body: some View {
        Group {
            if animationOption == .vinylSpin {
                ZStack {
                    // Outer Black Vinyl Disc
                    Circle()
                        .fill(Color(red: 0.08, green: 0.08, blue: 0.09))
                        .frame(width: size, height: size)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: isPlaying ? accentColor.opacity(0.4) : Color.black.opacity(0.4), radius: isPlaying ? 14 : 8, x: 0, y: 5)
                    
                    // Vinyl Grooves
                    ForEach([0.85, 0.7, 0.55], id: \.self) { ratio in
                        Circle()
                            .stroke(Color.white.opacity(0.04), lineWidth: 1)
                            .frame(width: size * ratio, height: size * ratio)
                    }
                    
                    // Center Album Cover
                    Group {
                        if let art = artwork {
                            Image(nsImage: art)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            ZStack {
                                accentColor.opacity(0.3)
                                Image(systemName: "music.note")
                                    .font(.system(size: size * 0.15, weight: .light))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    .frame(width: size * 0.45, height: size * 0.45)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(accentColor.opacity(0.5), lineWidth: 1.5))
                    
                    // Center Record Spindle Hole
                    Circle()
                        .fill(Color.black)
                        .frame(width: size * 0.08, height: size * 0.08)
                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                }
                .rotationEffect(.degrees(isPlaying ? 360 : 0))
                .animation(isPlaying ? .linear(duration: 8).repeatForever(autoreverses: false) : .default, value: isPlaying)
            } else if animationOption == .waveSpectrum {
                ZStack {
                    // Pulsing Spectrum Rings
                    ForEach(0..<3, id: \.self) { ring in
                        Circle()
                            .stroke(accentColor.opacity(isPlaying ? 0.35 / Double(ring + 1) : 0.08), lineWidth: isPlaying ? 3 : 1)
                            .frame(width: size + CGFloat(ring * 18), height: size + CGFloat(ring * 18))
                            .scaleEffect(isPlaying ? 1.05 : 1.0)
                            .animation(isPlaying ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(Double(ring) * 0.2) : .default, value: isPlaying)
                    }
                    
                    // Artwork Circle
                    Group {
                        if let art = artwork {
                            Image(nsImage: art)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            ZStack {
                                accentColor.opacity(0.3)
                                Image(systemName: "waveform")
                                    .font(.system(size: size * 0.35, weight: .light))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(isPlaying ? accentColor : Color.white.opacity(0.2), lineWidth: 2))
                    .shadow(color: isPlaying ? accentColor.opacity(0.5) : Color.black.opacity(0.3), radius: isPlaying ? 16 : 8)
                }
            } else if animationOption == .ambientAura {
                ZStack {
                    // Neon Aura Radial Glow
                    Circle()
                        .fill(accentColor.opacity(isPlaying ? 0.6 : 0.1))
                        .frame(width: size * 1.2, height: size * 1.2)
                        .blur(radius: 20)
                        .scaleEffect(isPlaying ? 1.1 : 1.0)
                        .animation(isPlaying ? .easeInOut(duration: 1.5).repeatForever(autoreverses: true) : .default, value: isPlaying)
                    
                    Group {
                        if let art = artwork {
                            Image(nsImage: art)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            ZStack {
                                Color(red: 0.18, green: 0.18, blue: 0.20)
                                Image(systemName: "sparkles")
                                    .font(.system(size: size * 0.35, weight: .light))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                    }
                    .frame(width: size, height: size)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isPlaying ? accentColor : Color.white.opacity(0.1), lineWidth: 1.5)
                    )
                    .shadow(color: isPlaying ? accentColor.opacity(0.7) : Color.black.opacity(0.4), radius: isPlaying ? 20 : 8)
                }
            } else if animationOption == .floatingCard {
                Group {
                    if let art = artwork {
                        Image(nsImage: art)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        ZStack {
                            Color(red: 0.18, green: 0.18, blue: 0.20)
                            Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: size * 0.35, weight: .light))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
                .frame(width: size, height: size)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.4), Color.clear]), startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                )
                .shadow(color: isPlaying ? accentColor.opacity(0.45) : Color.black.opacity(0.3), radius: isPlaying ? 22 : 10, x: 0, y: isPlaying ? 10 : 5)
                .rotation3DEffect(.degrees(isPlaying ? 6 : 0), axis: (x: 0.5, y: -0.5, z: 0))
            } else {
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
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
                .frame(width: size, height: size)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isPlaying ? accentColor.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: isPlaying ? accentColor.opacity(0.35) : Color.black.opacity(0.35), radius: isPlaying ? 14 : 8, x: 0, y: 5)
            }
        }
        .scaleEffect(isPlaying ? 1.03 : 1.0)
        .animation(animationOption.animation, value: isPlaying)
    }
}

struct ModernVisualizerView: View {
    let levels: [CGFloat]
    let accentColor: Color
    var style: VisualizerBarStyle = .verticalBars
    
    var body: some View {
        Group {
            switch style {
            case .verticalBars:
                HStack(spacing: 4) {
                    ForEach(0..<levels.count, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [accentColor, accentColor.opacity(0.6)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 4, height: max(4, levels[index] * 32))
                            .animation(.easeInOut(duration: 0.08), value: levels[index])
                    }
                }
                
            case .sineWaveform:
                GeometryReader { geo in
                    Path { path in
                        let width = geo.size.width
                        let height = geo.size.height
                        let midY = height / 2.0
                        let step = width / CGFloat(max(1, levels.count - 1))
                        
                        path.move(to: CGPoint(x: 0, y: midY))
                        for i in 0..<levels.count {
                            let x = CGFloat(i) * step
                            let dy = (levels[i] - 0.15) * (height * 0.8)
                            let y = (i % 2 == 0) ? midY - dy : midY + dy
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .shadow(color: accentColor.opacity(0.6), radius: 4)
                }
                .frame(width: 140, height: 32)
                
            case .glowingDots:
                HStack(spacing: 5) {
                    ForEach(0..<min(12, levels.count), id: \.self) { col in
                        VStack(spacing: 3) {
                            ForEach((0..<5).reversed(), id: \.self) { row in
                                let threshold = CGFloat(row + 1) / 5.0
                                let isLit = levels[col] >= threshold
                                Circle()
                                    .fill(isLit ? accentColor : Color.white.opacity(0.1))
                                    .frame(width: 5, height: 5)
                                    .shadow(color: isLit ? accentColor.opacity(0.8) : Color.clear, radius: 2)
                            }
                        }
                    }
                }
                
            case .floatingParticles:
                HStack(spacing: 6) {
                    ForEach(0..<min(10, levels.count), id: \.self) { index in
                        VStack {
                            Spacer()
                            Circle()
                                .fill(accentColor)
                                .frame(width: 6, height: 6)
                                .shadow(color: accentColor.opacity(0.8), radius: 4)
                                .offset(y: -levels[index] * 24)
                                .animation(.spring(response: 0.2, dampingFraction: 0.5), value: levels[index])
                        }
                        .frame(height: 32)
                    }
                }
                
            case .minimalPills:
                HStack(spacing: 8) {
                    let avgLeft = levels.prefix(8).reduce(0, +) / 8.0
                    let avgRight = levels.suffix(8).reduce(0, +) / 8.0
                    
                    Capsule()
                        .fill(accentColor)
                        .frame(width: max(8, avgLeft * 60), height: 6)
                        .animation(.easeInOut(duration: 0.08), value: avgLeft)
                    
                    Capsule()
                        .fill(accentColor.opacity(0.7))
                        .frame(width: max(8, avgRight * 60), height: 6)
                        .animation(.easeInOut(duration: 0.08), value: avgRight)
                }
                
            case .mirrorFrequency:
                HStack(spacing: 4) {
                    ForEach(0..<levels.count, id: \.self) { index in
                        let h = max(2, levels[index] * 16)
                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(accentColor)
                                .frame(width: 3.5, height: h)
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(accentColor.opacity(0.5))
                                .frame(width: 3.5, height: h)
                        }
                        .animation(.easeInOut(duration: 0.08), value: levels[index])
                    }
                }
                
            case .cyberpunkGrid:
                HStack(spacing: 4) {
                    ForEach(0..<min(12, levels.count), id: \.self) { index in
                        VStack(spacing: 2) {
                            // Peak Hold Segment Indicator
                            RoundedRectangle(cornerRadius: 1)
                                .fill(accentColor)
                                .frame(width: 5, height: 2)
                                .offset(y: -max(0, levels[index] * 20))
                                .animation(.easeOut(duration: 0.2), value: levels[index])
                            
                            VStack(spacing: 2) {
                                ForEach((0..<6).reversed(), id: \.self) { seg in
                                    let threshold = CGFloat(seg + 1) / 6.0
                                    let active = levels[index] >= threshold
                                    let color: Color = seg >= 4 ? .red : (seg >= 2 ? .yellow : accentColor)
                                    
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(active ? color : Color.white.opacity(0.08))
                                        .frame(width: 5, height: 3)
                                }
                            }
                        }
                    }
                }
                
            case .circularOrbit:
                ZStack {
                    Circle()
                        .stroke(accentColor.opacity(0.2), lineWidth: 1.5)
                        .frame(width: 28, height: 28)
                    
                    ForEach(0..<12, id: \.self) { i in
                        let angle = Double(i) * (360.0 / 12.0)
                        let lvl = levels[i % levels.count]
                        Capsule()
                            .fill(accentColor)
                            .frame(width: 2.5, height: max(4, lvl * 12))
                            .offset(y: -16)
                            .rotationEffect(.degrees(angle))
                    }
                }
                .frame(width: 36, height: 36)
                
            case .liquidFlow:
                GeometryReader { geo in
                    Path { path in
                        let w = geo.size.width
                        let h = geo.size.height
                        let mid = h / 2.0
                        let pts = levels.count
                        
                        path.move(to: CGPoint(x: 0, y: mid))
                        for i in 0..<pts {
                            let x = CGFloat(i) * (w / CGFloat(pts - 1))
                            let dy = (levels[i] - 0.2) * (h * 0.4)
                            let y = mid + (i % 2 == 0 ? dy : -dy)
                            path.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x - 5, y: mid))
                        }
                        path.addLine(to: CGPoint(x: w, y: h))
                        path.addLine(to: CGPoint(x: 0, y: h))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [accentColor.opacity(0.8), accentColor.opacity(0.1)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(width: 140, height: 32)
                
            case .strobeBeat:
                HStack(spacing: 6) {
                    ForEach(0..<min(8, levels.count), id: \.self) { index in
                        let lvl = levels[index]
                        Circle()
                            .stroke(accentColor, lineWidth: max(1, lvl * 4))
                            .background(Circle().fill(accentColor.opacity(Double(lvl) * 0.6)))
                            .frame(width: max(8, lvl * 22), height: max(8, lvl * 22))
                            .animation(.spring(response: 0.15, dampingFraction: 0.6), value: lvl)
                    }
                }
            }
        }
        .frame(height: 36)
    }
}

// MARK: - Menu Bar Popup HUD View

struct StatusBarPopoverView: View {
    @ObservedObject var engine: AudioEngine
    
    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                ArtworkView(artwork: engine.currentTrack?.artwork, size: 54, isPlaying: engine.isPlaying, accentColor: engine.activeAccentColor)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(engine.currentTrack?.title ?? "No Track Playing")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                        .lineLimit(1)
                    
                    Text(engine.currentTrack?.artist ?? "San Music Player")
                        .font(.system(size: 11))
                        .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                        .lineLimit(1)
                    
                    if let track = engine.currentTrack {
                        Text(track.audioBadgeText)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(engine.activeAccentColor)
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
            
            ModernVisualizerView(levels: engine.visualizerLevels, accentColor: engine.activeAccentColor, style: engine.visualizerBarStyle)
            
            HStack(spacing: 14) {
                Button(action: { engine.previousTrack() }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 14))
                        .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                }.buttonStyle(PlainButtonStyle())
                
                Button(action: { engine.togglePlay() }) {
                    ZStack {
                        Circle()
                            .fill(engine.activeAccentColor)
                            .frame(width: 32, height: 32)
                        Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                    }
                }.buttonStyle(PlainButtonStyle())
                
                Button(action: { engine.nextTrack() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 14))
                        .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                }.buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Button(action: {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first {
                        window.makeKeyAndOrderFront(nil)
                    }
                }) {
                    Text("Open San")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(engine.activeAccentColor)
                }.buttonStyle(PlainButtonStyle())
            }
        }
        .padding(14)
        .frame(width: 280)
        .background(UniformDesign.bgCard(mode: engine.appearanceMode))
    }
}

// MARK: - USB / DAP Sync Progress Modal Sheet

struct USBSyncProgressSheet: View {
    @ObservedObject var engine: AudioEngine
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "externaldrive.fill.badge.plus")
                    .font(.system(size: 24))
                    .foregroundColor(engine.activeAccentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("USB Drive / DAP Direct Sync")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                    
                    Text("Copying audio files & creating relative .m3u8 playlist")
                        .font(.system(size: 12))
                        .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(engine.syncStatusText)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                    .lineLimit(1)
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 8)
                        Capsule()
                            .fill(engine.activeAccentColor)
                            .frame(width: max(0, geo.size.width * CGFloat(engine.syncProgress)), height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(UniformDesign.bgCard(mode: engine.appearanceMode))
            )
            
            HStack {
                Spacer()
                
                if engine.isSyncingToUSB {
                    Button("Cancel Sync") {
                        engine.cancelUSBSync()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.red.opacity(0.15)))
                } else {
                    Button("Done") {
                        engine.showSyncDrawer = false
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.black)
                    .font(.system(size: 13, weight: .bold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(engine.activeAccentColor))
                }
            }
        }
        .padding(24)
        .frame(width: 460)
        .background(UniformDesign.bgMain(mode: engine.appearanceMode))
    }
}

// MARK: - Play Queue Drawer Sheet

struct PlayQueueDrawerSheet: View {
    @ObservedObject var engine: AudioEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "list.bullet.indent")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(engine.activeAccentColor)
                    Text("Up Next Play Queue")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                }
                
                Spacer()
                
                if !engine.playQueue.isEmpty {
                    Button(action: { engine.clearQueue() }) {
                        Text("Clear Queue")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button(action: { engine.showQueueDrawer = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if engine.playQueue.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "music.note.list")
                        .font(.system(size: 36))
                        .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                    Text("Queue is empty")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                    Text("Right-click or tap 'Play Next' / 'Add to Queue' on any song to add it here.")
                        .font(.system(size: 12))
                        .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: 240)
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(Array(engine.playQueue.enumerated()), id: \.offset) { index, track in
                            HStack(spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                                    .frame(width: 20, alignment: .trailing)
                                
                                ArtworkView(artwork: track.artwork, size: 30)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(track.title)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                                        .lineLimit(1)
                                    Text(track.artist)
                                        .font(.system(size: 11))
                                        .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Button(action: { engine.removeFromQueue(at: index) }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 11))
                                        .foregroundColor(.red.opacity(0.8))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(UniformDesign.hoverHighlight(mode: engine.appearanceMode))
                            )
                        }
                    }
                }
                .frame(maxHeight: 280)
            }
        }
        .padding(20)
        .frame(width: 420)
        .background(UniformDesign.bgCard(mode: engine.appearanceMode))
        .cornerRadius(16)
        .shadow(radius: 20)
    }
}

// MARK: - Track Inspector Sheet

struct TrackInspectorView: View {
    let track: Track
    @ObservedObject var engine: AudioEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Track Inspector")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                Spacer()
                Button(action: { engine.inspectingTrack = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                }.buttonStyle(PlainButtonStyle())
            }
            
            HStack(spacing: 20) {
                ArtworkView(artwork: track.artwork, size: 100)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(track.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                    Text(track.artist)
                        .font(.system(size: 13))
                        .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                    Text(track.album)
                        .font(.system(size: 12))
                        .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                    
                    Text(track.audioBadgeText)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(engine.activeAccentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(engine.activeAccentColor.opacity(0.15)))
                        .padding(.top, 4)
                }
            }
            
            ModernCard(cornerRadius: 12, mode: engine.appearanceMode) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("File Size:")
                            .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                        Spacer()
                        Text(track.fileSizeString)
                            .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                    }
                    Divider().background(UniformDesign.borderSubtle(mode: engine.appearanceMode))
                    
                    HStack {
                        Text("Channels:")
                            .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                        Spacer()
                        Text(track.channelCount == 2 ? "Stereo (2 Channels)" : "Mono (1 Channel)")
                            .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                    }
                    Divider().background(UniformDesign.borderSubtle(mode: engine.appearanceMode))
                    
                    HStack {
                        Text("File Path:")
                            .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                        Spacer()
                        Text(track.url.path)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                            .lineLimit(1)
                    }
                }
                .font(.system(size: 12))
                .padding(16)
            }
        }
        .padding(24)
        .frame(width: 480)
        .background(UniformDesign.bgCard(mode: engine.appearanceMode))
        .cornerRadius(16)
        .shadow(radius: 20)
    }
}

// MARK: - Mini Player Layout View

struct MiniPlayerView: View {
    @ObservedObject var engine: AudioEngine
    
    var body: some View {
        ZStack {
            UniformDesign.bgSidebar(mode: engine.appearanceMode)
                .ignoresSafeArea()
            
            HStack(spacing: 12) {
                ArtworkView(artwork: engine.currentTrack?.artwork, size: 60)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(engine.currentTrack?.title ?? "No Song Playing")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                        .lineLimit(1)
                    
                    Text(engine.currentTrack?.artist ?? "Select a track")
                        .font(.system(size: 11))
                        .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                        .lineLimit(1)
                    
                    // Transport controls
                    HStack(spacing: 12) {
                        Button(action: { engine.previousTrack() }) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 12))
                                .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                        }.buttonStyle(PlainButtonStyle())
                        
                        Button(action: { engine.togglePlay() }) {
                            Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(engine.activeAccentColor)
                        }.buttonStyle(PlainButtonStyle())
                        
                        Button(action: { engine.nextTrack() }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 12))
                                .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                        }.buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        Button(action: { engine.toggleMiniPlayer() }) {
                            Image(systemName: "rectangle.expand.vertical")
                                .font(.system(size: 11))
                                .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                        }.buttonStyle(PlainButtonStyle())
                    }
                    .padding(.top, 2)
                }
            }
            .padding(12)
        }
    }
}

// MARK: - Custom Equalizer Vertical Fader Component

struct CustomVerticalFader: View {
    @Binding var gain: Float // -12 to +12
    let accentColor: Color
    let mode: AppearanceMode
    let onCommit: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            let normalized = CGFloat((gain + 12) / 24) // 0.0 to 1.0
            let thumbY = height * (1.0 - normalized)
            let midY = height * 0.5
            
            ZStack(alignment: .top) {
                // Background Track
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 6, height: height)
                
                // 0dB Center Marker Line
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 14, height: 1.5)
                    .offset(y: midY)
                
                // Active Fill Bar from Midpoint (0dB)
                let fillHeight = abs(thumbY - midY)
                let fillTop = min(thumbY, midY)
                
                Capsule()
                    .fill(accentColor)
                    .frame(width: 6, height: fillHeight)
                    .offset(y: fillTop)
                
                // Draggable Handle Pill
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white)
                    .frame(width: 28, height: 14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(accentColor, lineWidth: 1.5)
                    )
                    .shadow(color: accentColor.opacity(0.4), radius: 4, x: 0, y: 2)
                    .offset(y: max(0, min(height - 14, thumbY - 7)))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let clampedY = max(0, min(height, gesture.location.y))
                        let percent = 1.0 - (clampedY / height)
                        let newGain = Float(percent * 24.0 - 12.0)
                        self.gain = max(-12, min(12, newGain))
                    }
                    .onEnded { _ in
                        onCommit()
                    }
            )
        }
        .frame(width: 36, height: 170)
    }
}

// MARK: - Equalizer View Component

struct EqualizerView: View {
    @ObservedObject var engine: AudioEngine
    let bandLabels = ["60Hz", "230Hz", "910Hz", "3.6kHz", "14kHz"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Graphic Equalizer & Audio Controls")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                
                Spacer()
                
                Button(action: {
                    engine.applyEQPreset(.flat)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 11))
                        Text("Reset EQ")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(UniformDesign.hoverHighlight(mode: engine.appearanceMode)))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Audio Controls (Speed & Pan)
            ModernCard(cornerRadius: 14, mode: engine.appearanceMode) {
                HStack(spacing: 32) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Playback Speed: \(String(format: "%.2fx", engine.playbackRate))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                        
                        HStack(spacing: 8) {
                            ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { rate in
                                Button(action: { engine.playbackRate = Float(rate) }) {
                                    Text(String(format: "%.2fx", rate))
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(engine.playbackRate == Float(rate) ? .black : UniformDesign.textPrimary(mode: engine.appearanceMode))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(engine.playbackRate == Float(rate) ? engine.activeAccentColor : UniformDesign.hoverHighlight(mode: engine.appearanceMode)))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Stereo Balance (Pan): \(String(format: "%.1f", engine.pan))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                        
                        HStack(spacing: 8) {
                            Text("L")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                            Slider(value: $engine.pan, in: -1.0...1.0)
                                .accentColor(engine.activeAccentColor)
                                .frame(width: 120)
                            Text("R")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                        }
                    }
                }
                .padding(20)
            }
            
            // Preset Buttons
            HStack(spacing: 10) {
                ForEach(EQPreset.allCases) { preset in
                    Button(action: { engine.applyEQPreset(preset) }) {
                        Text(preset.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(engine.selectedEQPreset == preset ? .black : UniformDesign.textPrimary(mode: engine.appearanceMode))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(engine.selectedEQPreset == preset ? engine.activeAccentColor : UniformDesign.hoverHighlight(mode: engine.appearanceMode))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // EQ Band Vertical Faders
            ModernCard(cornerRadius: 14, mode: engine.appearanceMode) {
                HStack(spacing: 40) {
                    ForEach(0..<5, id: \.self) { index in
                        VStack(spacing: 12) {
                            Text(String(format: "%+.1fdB", engine.eqGains[index]))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(engine.eqGains[index] != 0 ? engine.activeAccentColor : UniformDesign.textMuted(mode: engine.appearanceMode))
                            
                            CustomVerticalFader(
                                gain: $engine.eqGains[index],
                                accentColor: engine.activeAccentColor,
                                mode: engine.appearanceMode
                            ) {
                                engine.saveLibrary()
                            }
                            
                            Text(bandLabels[index])
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                        }
                    }
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 32)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Album Grid View Component

struct AlbumsGridView: View {
    @ObservedObject var engine: AudioEngine
    let columns = [GridItem(.adaptive(minimum: 160), spacing: 20)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let selected = engine.selectedAlbum {
                // Detailed Album Track View
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Button(action: { engine.selectedAlbum = nil }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                Text("Back to Albums")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(engine.activeAccentColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 24) {
                        ArtworkView(artwork: selected.artwork, size: 140, isPlaying: engine.currentTrack?.album == selected.name && engine.isPlaying, accentColor: engine.activeAccentColor)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(selected.name)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                            Text(selected.artist)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                            Text("\(selected.tracks.count) tracks")
                                .font(.system(size: 12))
                                .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                            
                            Button(action: {
                                if let first = selected.tracks.first {
                                    engine.loadAndPlay(track: first)
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "play.fill")
                                    Text("Play Album")
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(engine.activeAccentColor))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 6)
                        }
                    }
                    
                    VStack(spacing: 2) {
                        ForEach(Array(selected.tracks.enumerated()), id: \.element.id) { index, track in
                            let isHovered = engine.hoveredTrackId == track.id
                            let isSelected = engine.currentTrack == track
                            
                            HStack(spacing: 14) {
                                Text("\(index + 1)")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                                    .frame(width: 24, alignment: .trailing)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(track.title)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(isSelected ? engine.activeAccentColor : UniformDesign.textPrimary(mode: engine.appearanceMode))
                                        .lineLimit(1)
                                    Text(track.artist)
                                        .font(.system(size: 11))
                                        .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Text(formatTime(track.duration))
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                                
                                Button(action: { engine.loadAndPlay(track: track) }) {
                                    Image(systemName: isSelected && engine.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                                        .padding(6)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isSelected ? UniformDesign.activeHighlight(mode: engine.appearanceMode) : (isHovered ? UniformDesign.hoverHighlight(mode: engine.appearanceMode) : Color.clear))
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                engine.loadAndPlay(track: track)
                            }
                            .onHover { hovering in
                                engine.hoveredTrackId = hovering ? track.id : nil
                            }
                            .contextMenu {
                                Button("Play Next") { engine.playNext(track: track) }
                                Button("Add to Queue") { engine.addToQueue(track: track) }
                                Button(engine.isFavorite(track: track) ? "Remove from Favorites" : "Add to Favorites") { engine.toggleFavorite(track: track) }
                            }
                        }
                    }
                }
            } else {
                // Album Cards Grid
                Text("Albums Library (\(engine.albumsList.count))")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                
                if engine.albumsList.isEmpty {
                    ModernCard(cornerRadius: 14, mode: engine.appearanceMode) {
                        VStack(spacing: 12) {
                            Image(systemName: "square.grid.2x2.fill")
                                .font(.system(size: 36))
                                .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                            Text("No albums found in library")
                                .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                        }
                        .padding(40)
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(engine.albumsList) { albumGroup in
                            Button(action: { engine.selectedAlbum = albumGroup }) {
                                VStack(alignment: .leading, spacing: 10) {
                                    ArtworkView(artwork: albumGroup.artwork, size: 160, isPlaying: engine.currentTrack?.album == albumGroup.name && engine.isPlaying, accentColor: engine.activeAccentColor)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(albumGroup.name)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                                            .lineLimit(1)
                                        Text(albumGroup.artist)
                                            .font(.system(size: 11))
                                            .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                                            .lineLimit(1)
                                        Text("\(albumGroup.tracks.count) tracks")
                                            .font(.system(size: 10))
                                            .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(UniformDesign.bgCard(mode: engine.appearanceMode))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(UniformDesign.borderSubtle(mode: engine.appearanceMode), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        guard !seconds.isNaN && seconds >= 0 else { return "00:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Artists Page Component (Auto-Detect Albums per Artist)

struct ArtistsView: View {
    @ObservedObject var engine: AudioEngine
    let columns = [GridItem(.adaptive(minimum: 160), spacing: 20)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let artist = engine.selectedArtist {
                // Detailed Artist Page
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        Button(action: { engine.selectedArtist = nil }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                Text("Back to Artists")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(engine.activeAccentColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                    }
                    
                    // Artist Banner Card
                    HStack(spacing: 24) {
                        // Circular Artist Avatar Artwork
                        Group {
                            if let art = artist.artwork {
                                Image(nsImage: art)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                ZStack {
                                    engine.activeAccentColor.opacity(0.3)
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40, weight: .light))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(engine.activeAccentColor, lineWidth: 2))
                        .shadow(color: engine.activeAccentColor.opacity(0.3), radius: 12)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(artist.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                            
                            HStack(spacing: 12) {
                                Text("\(artist.albums.count) Auto-Detected Albums")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(engine.activeAccentColor)
                                
                                Text("•")
                                    .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                                
                                Text("\(artist.tracks.count) Songs")
                                    .font(.system(size: 12))
                                    .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                            }
                            
                            Button(action: {
                                if let first = artist.tracks.first {
                                    engine.loadAndPlay(track: first)
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "play.fill")
                                    Text("Play All Artist Tracks")
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(engine.activeAccentColor))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 6)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(UniformDesign.bgCard(mode: engine.appearanceMode))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(UniformDesign.borderSubtle(mode: engine.appearanceMode), lineWidth: 1)
                            )
                    )
                    
                    // Auto-Detected Albums by Artist Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Auto-Detected Albums (\(artist.albums.count))")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                        
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(artist.albums) { album in
                                Button(action: {
                                    engine.selectedAlbum = album
                                    engine.selectedNav = .albums
                                }) {
                                    VStack(alignment: .leading, spacing: 10) {
                                        ArtworkView(artwork: album.artwork, size: 150, isPlaying: engine.currentTrack?.album == album.name && engine.isPlaying, accentColor: engine.activeAccentColor)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(album.name)
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                                                .lineLimit(1)
                                            Text("\(album.tracks.count) tracks")
                                                .font(.system(size: 11))
                                                .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                                        }
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(UniformDesign.bgCard(mode: engine.appearanceMode))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(UniformDesign.borderSubtle(mode: engine.appearanceMode), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    // All Songs by Artist Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("All Songs by \(artist.name)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                        
                        VStack(spacing: 2) {
                            ForEach(Array(artist.tracks.enumerated()), id: \.element.id) { index, track in
                                let isHovered = engine.hoveredTrackId == track.id
                                let isSelected = engine.currentTrack == track
                                
                                HStack(spacing: 14) {
                                    Text("\(index + 1)")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                                        .frame(width: 24, alignment: .trailing)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(track.title)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(isSelected ? engine.activeAccentColor : UniformDesign.textPrimary(mode: engine.appearanceMode))
                                            .lineLimit(1)
                                        Text(track.album)
                                            .font(.system(size: 11))
                                            .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(formatTime(track.duration))
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                                    
                                    Button(action: { engine.loadAndPlay(track: track) }) {
                                        Image(systemName: isSelected && engine.isPlaying ? "pause.fill" : "play.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                                            .padding(6)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(isSelected ? UniformDesign.activeHighlight(mode: engine.appearanceMode) : (isHovered ? UniformDesign.hoverHighlight(mode: engine.appearanceMode) : Color.clear))
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    engine.loadAndPlay(track: track)
                                }
                                .onHover { hovering in
                                    engine.hoveredTrackId = hovering ? track.id : nil
                                }
                            }
                        }
                    }
                }
            } else {
                // Artists Overview Grid
                Text("Artists Library (\(engine.artistsList.count))")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                
                if engine.artistsList.isEmpty {
                    ModernCard(cornerRadius: 14, mode: engine.appearanceMode) {
                        VStack(spacing: 12) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 36))
                                .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                            Text("No artists found in library")
                                .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                        }
                        .padding(40)
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(engine.artistsList) { artistGroup in
                            Button(action: { engine.selectedArtist = artistGroup }) {
                                VStack(alignment: .center, spacing: 12) {
                                    // Circular Artist Cover Art Avatar
                                    Group {
                                        if let art = artistGroup.artwork {
                                            Image(nsImage: art)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } else {
                                            ZStack {
                                                engine.activeAccentColor.opacity(0.2)
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 36, weight: .light))
                                                    .foregroundColor(.white.opacity(0.6))
                                            }
                                        }
                                    }
                                    .frame(width: 110, height: 110)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(UniformDesign.borderSubtle(mode: engine.appearanceMode), lineWidth: 1))
                                    .shadow(color: Color.black.opacity(0.3), radius: 6)
                                    
                                    VStack(spacing: 3) {
                                        Text(artistGroup.name)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                                            .lineLimit(1)
                                        Text("\(artistGroup.albums.count) Albums • \(artistGroup.tracks.count) Songs")
                                            .font(.system(size: 10))
                                            .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                                            .lineLimit(1)
                                    }
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(UniformDesign.bgCard(mode: engine.appearanceMode))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(UniformDesign.borderSubtle(mode: engine.appearanceMode), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        guard !seconds.isNaN && seconds >= 0 else { return "00:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Folder Mode View Component

struct FolderModeView: View {
    @ObservedObject var engine: AudioEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Folder Mode")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                    
                    if let folder = engine.selectedFolderURL {
                        Text(folder.path)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                            .lineLimit(1)
                    } else {
                        Text("No folder selected")
                            .font(.system(size: 12))
                            .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                    }
                }
                
                Spacer()
                
                Button(action: { engine.selectFolderToPlay() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "folder.badge.plus")
                        Text("Select Folder...")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(engine.activeAccentColor.opacity(0.8))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if engine.folderTracks.isEmpty {
                ModernCard(cornerRadius: 14, mode: engine.appearanceMode) {
                    VStack(spacing: 14) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 40))
                            .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                        Text("Select a folder to play music directly from it")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                        Text("San will scan all MP3, WAV, FLAC, M4A files in the selected folder and subfolders.")
                            .font(.system(size: 12))
                            .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                    }
                    .padding(40)
                    .frame(maxWidth: .infinity)
                }
            } else {
                VStack(spacing: 2) {
                    ForEach(Array(engine.folderTracks.enumerated()), id: \.element.id) { index, track in
                        let isHovered = engine.hoveredTrackId == track.id
                        let isSelected = engine.currentTrack == track
                        
                        HStack(spacing: 14) {
                            Text("\(index + 1)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                                .frame(width: 24, alignment: .trailing)
                            
                            ArtworkView(artwork: track.artwork, size: 32)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.title)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(isSelected ? engine.activeAccentColor : UniformDesign.textPrimary(mode: engine.appearanceMode))
                                    .lineLimit(1)
                                Text(track.artist)
                                    .font(.system(size: 11))
                                    .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Text(track.audioBadgeText)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                            
                            Text(formatTime(track.duration))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                            
                            Button(action: { engine.loadAndPlay(track: track) }) {
                                Image(systemName: isSelected && engine.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                                    .padding(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected ? UniformDesign.activeHighlight(mode: engine.appearanceMode) : (isHovered ? UniformDesign.hoverHighlight(mode: engine.appearanceMode) : Color.clear))
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            engine.loadAndPlay(track: track)
                        }
                        .onHover { hovering in
                            engine.hoveredTrackId = hovering ? track.id : nil
                        }
                        .contextMenu {
                            Button("Play Next") { engine.playNext(track: track) }
                            Button("Add to Queue") { engine.addToQueue(track: track) }
                            Button(engine.isFavorite(track: track) ? "Remove from Favorites" : "Add to Favorites") { engine.toggleFavorite(track: track) }
                            Button("Inspect File") { engine.inspectingTrack = track }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        guard !seconds.isNaN && seconds >= 0 else { return "00:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Settings View Component

struct SettingsView: View {
    @ObservedObject var engine: AudioEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Settings & Customization")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
            
            // Appearance Mode Selector (Dark, Pitch Black, Light)
            ModernCard(cornerRadius: 14, mode: engine.appearanceMode) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Appearance Mode")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                    
                    HStack(spacing: 12) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Button(action: {
                                engine.appearanceMode = mode
                                engine.saveLibrary()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: mode == .light ? "sun.max.fill" : (mode == .pitchBlack ? "moon.stars.fill" : "moon.fill"))
                                    Text(mode.rawValue)
                                }
                                .font(.system(size: 12, weight: engine.appearanceMode == mode ? .bold : .medium))
                                .foregroundColor(engine.appearanceMode == mode ? .black : UniformDesign.textPrimary(mode: engine.appearanceMode))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule().fill(engine.appearanceMode == mode ? engine.activeAccentColor : UniformDesign.hoverHighlight(mode: engine.appearanceMode))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    Toggle(isOn: Binding(
                        get: { engine.useDynamicArtworkTheme },
                        set: {
                            engine.useDynamicArtworkTheme = $0
                            engine.saveLibrary()
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dynamic Album Artwork Theme")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                            Text("Automatically sample vibrant accent colors from playing album artwork.")
                                .font(.system(size: 11))
                                .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: engine.activeAccentColor))
                    .padding(.top, 6)
                    
                    Toggle(isOn: Binding(
                        get: { engine.enableSliceOfLifeTheme },
                        set: {
                            engine.enableSliceOfLifeTheme = $0
                            engine.saveLibrary()
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Slice of Life Anime Theme & Mascot")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                            Text("Render cute slice of life anime mascot leaning against title with cozy lo-fi background theme.")
                                .font(.system(size: 11))
                                .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: engine.activeAccentColor))
                    .padding(.top, 6)
                    
                    Toggle(isOn: Binding(
                        get: { engine.enableSidebarLiquidGlass },
                        set: {
                            engine.enableSidebarLiquidGlass = $0
                            engine.saveLibrary()
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Liquid Glass Sidebar Backdrop")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                            Text("Apply translucent optical frosted glass material behind the sidebar navigation list.")
                                .font(.system(size: 11))
                                .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: engine.activeAccentColor))
                    .padding(.top, 6)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Player Visualizer & Motion Animation Options Section
            ModernCard(cornerRadius: 14, mode: engine.appearanceMode) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Player Visualizer & Motion Options")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                    
                    Text("Select your preferred artwork presentation, audio visualizer ring, and motion style:")
                        .font(.system(size: 12))
                        .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                        ForEach(PlayerAnimationOption.allCases) { option in
                            let iconName: String = {
                                switch option {
                                case .smoothSpring: return "sparkles"
                                case .vinylSpin: return "record.circle.fill"
                                case .waveSpectrum: return "waveform"
                                case .floatingCard: return "square.stack.3d.up.fill"
                                case .ambientAura: return "sun.max.fill"
                                case .gentleEase: return "wave.3.right"
                                case .snappyLinear: return "bolt.fill"
                                }
                            }()
                            
                            Button(action: {
                                withAnimation(option.animation) {
                                    engine.playerAnimation = option
                                    engine.saveLibrary()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: iconName)
                                        .font(.system(size: 12))
                                    Text(option.rawValue)
                                        .font(.system(size: 11, weight: engine.playerAnimation == option ? .bold : .medium))
                                        .lineLimit(1)
                                }
                                .foregroundColor(engine.playerAnimation == option ? .black : UniformDesign.textPrimary(mode: engine.appearanceMode))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(engine.playerAnimation == option ? engine.activeAccentColor : UniformDesign.hoverHighlight(mode: engine.appearanceMode))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(engine.playerAnimation == option ? engine.activeAccentColor : UniformDesign.borderSubtle(mode: engine.appearanceMode), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Audio Spectrum Bar Visualizer Options Section
            ModernCard(cornerRadius: 14, mode: engine.appearanceMode) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Audio Spectrum Bar Visualizer Style")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                            
                            Text("Select how the live audio waveform spectrum bars render on the player stage and popover:")
                                .font(.system(size: 12))
                                .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                        }
                        
                        Spacer()
                        
                        // Live Preview Box
                        ModernVisualizerView(levels: [0.3, 0.7, 0.5, 0.9, 0.4, 0.8, 0.6, 0.3], accentColor: engine.activeAccentColor, style: engine.visualizerBarStyle)
                    }
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                        ForEach(VisualizerBarStyle.allCases) { style in
                            let iconName: String = {
                                switch style {
                                case .verticalBars: return "chart.bar.fill"
                                case .sineWaveform: return "waveform.path"
                                case .glowingDots: return "circle.grid.3x3.fill"
                                case .floatingParticles: return "sparkles"
                                case .minimalPills: return "slider.horizontal.3"
                                case .mirrorFrequency: return "arrow.up.and.down"
                                case .cyberpunkGrid: return "bolt.horizontal.fill"
                                case .circularOrbit: return "circle.dashed"
                                case .liquidFlow: return "drop.fill"
                                case .strobeBeat: return "circle.badge.plus"
                                }
                            }()
                            
                            Button(action: {
                                withAnimation(.spring()) {
                                    engine.visualizerBarStyle = style
                                    engine.saveLibrary()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: iconName)
                                        .font(.system(size: 12))
                                    Text(style.rawValue)
                                        .font(.system(size: 11, weight: engine.visualizerBarStyle == style ? .bold : .medium))
                                        .lineLimit(1)
                                }
                                .foregroundColor(engine.visualizerBarStyle == style ? .black : UniformDesign.textPrimary(mode: engine.appearanceMode))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(engine.visualizerBarStyle == style ? engine.activeAccentColor : UniformDesign.hoverHighlight(mode: engine.appearanceMode))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(engine.visualizerBarStyle == style ? engine.activeAccentColor : UniformDesign.borderSubtle(mode: engine.appearanceMode), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Accent Color Picker Section
            ModernCard(cornerRadius: 14, mode: engine.appearanceMode) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Fallback Accent Theme")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                    
                    Text("Select your accent highlight color when dynamic artwork theme is off:")
                        .font(.system(size: 12))
                        .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                    
                    HStack(spacing: 16) {
                        ForEach(AccentTheme.allCases) { theme in
                            Button(action: { engine.setAccentTheme(theme) }) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(theme.color)
                                        .frame(width: 16, height: 16)
                                        .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1))
                                    
                                    Text(theme.rawValue)
                                        .font(.system(size: 12, weight: engine.currentAccent == theme ? .bold : .regular))
                                        .foregroundColor(engine.currentAccent == theme ? UniformDesign.textPrimary(mode: engine.appearanceMode) : UniformDesign.textSecondary(mode: engine.appearanceMode))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(engine.currentAccent == theme ? UniformDesign.activeHighlight(mode: engine.appearanceMode) : UniformDesign.hoverHighlight(mode: engine.appearanceMode))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(engine.currentAccent == theme ? theme.color : UniformDesign.borderSubtle(mode: engine.appearanceMode), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Audio Playback & Crossfade Section
            ModernCard(cornerRadius: 14, mode: engine.appearanceMode) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Audio Playback & Crossfade")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                    
                    Text("Set the smooth overlap transition duration between songs:")
                        .font(.system(size: 12))
                        .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                    
                    HStack(spacing: 12) {
                        ForEach(CrossfadeDuration.allCases) { option in
                            Button(action: {
                                engine.crossfadeDuration = option
                                engine.saveLibrary()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: option == .off ? "speaker.fill" : "wave.3.left.and.right")
                                    Text(option.rawValue)
                                }
                                .font(.system(size: 12, weight: engine.crossfadeDuration == option ? .bold : .medium))
                                .foregroundColor(engine.crossfadeDuration == option ? .black : UniformDesign.textPrimary(mode: engine.appearanceMode))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule().fill(engine.crossfadeDuration == option ? engine.activeAccentColor : UniformDesign.hoverHighlight(mode: engine.appearanceMode))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Sleep Timer Section
            ModernCard(cornerRadius: 14, mode: engine.appearanceMode) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Sleep Timer")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                        Spacer()
                        if engine.sleepTimerRemainingSeconds > 0 {
                            Text("Stopping in \(engine.sleepTimerRemainingSeconds / 60):\(String(format: "%02d", engine.sleepTimerRemainingSeconds % 60))")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(engine.activeAccentColor)
                        }
                    }
                    
                    HStack(spacing: 10) {
                        ForEach([0, 15, 30, 45, 60, -1], id: \.self) { mins in
                            Button(action: { engine.setSleepTimer(minutes: mins) }) {
                                Text(mins == 0 ? "Off" : (mins == -1 ? "End of Track" : "\(mins) mins"))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(engine.sleepTimerMinutes == mins ? .black : UniformDesign.textPrimary(mode: engine.appearanceMode))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(engine.sleepTimerMinutes == mins ? engine.activeAccentColor : UniformDesign.hoverHighlight(mode: engine.appearanceMode)))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // About & System Engine Info
            ModernCard(cornerRadius: 14, mode: engine.appearanceMode) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("System Information")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Audio Engine:")
                                .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                            Spacer()
                            Text("Apple AVFoundation (Hardware Decoded)")
                                .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                        }
                        Divider().background(UniformDesign.borderSubtle(mode: engine.appearanceMode))
                        
                        HStack {
                            Text("Engine Status:")
                                .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                            Spacer()
                            Text("Active (Local)")
                                .foregroundColor(engine.activeAccentColor)
                        }
                        Divider().background(UniformDesign.borderSubtle(mode: engine.appearanceMode))
                        
                        HStack {
                            Text("Architecture:")
                                .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                            Spacer()
                            Text("Native Apple Silicon (ARM64)")
                                .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                        }
                        Divider().background(UniformDesign.borderSubtle(mode: engine.appearanceMode))
                        
                        HStack {
                            Text("Supported Formats:")
                                .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                            Spacer()
                            Text("FLAC, WAV, MP3, AAC, M4A")
                                .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                        }
                    }
                    .font(.system(size: 12, design: .monospaced))
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Sidebar Helper Views

struct SidebarSectionView<Content: View>: View {
    let title: String
    @ObservedObject var engine: AudioEngine
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: engine.isSidebarCollapsed ? .center : .leading, spacing: 4) {
            if !engine.isSidebarCollapsed {
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                    .padding(.horizontal, 10)
                    .padding(.bottom, 2)
            }
            
            content
        }
    }
}

struct SidebarNavItemButton: View {
    let item: NavigationItem
    @ObservedObject var engine: AudioEngine
    
    var isSelected: Bool {
        engine.selectedNav == item
    }
    
    var body: some View {
        Button(action: {
            withAnimation(engine.playerAnimation.animation) {
                engine.selectedNav = item
            }
        }) {
            if engine.isSidebarCollapsed {
                ZStack {
                    Image(systemName: item.iconName)
                        .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? engine.activeAccentColor : UniformDesign.textMuted(mode: engine.appearanceMode))
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(isSelected ? UniformDesign.activeHighlight(mode: engine.appearanceMode) : Color.clear)
                        )
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .help(item.rawValue)
            } else {
                HStack(spacing: 12) {
                    Image(systemName: item.iconName)
                        .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? engine.activeAccentColor : UniformDesign.textMuted(mode: engine.appearanceMode))
                        .frame(width: 20, alignment: .center)
                    
                    Text(item.rawValue)
                        .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? UniformDesign.textPrimary(mode: engine.appearanceMode) : UniformDesign.textSecondary(mode: engine.appearanceMode))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if isSelected {
                        Capsule()
                            .fill(engine.activeAccentColor)
                            .frame(width: 3, height: 14)
                    }
                }
                .padding(.vertical, 7)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? UniformDesign.activeHighlight(mode: engine.appearanceMode) : Color.clear)
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
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
        
        if !engine.searchText.isEmpty {
            baseList = baseList.filter {
                $0.title.localizedCaseInsensitiveContains(engine.searchText) ||
                $0.artist.localizedCaseInsensitiveContains(engine.searchText) ||
                $0.album.localizedCaseInsensitiveContains(engine.searchText)
            }
        }
        
        switch engine.currentSort {
        case .title:
            return baseList.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .artist:
            return baseList.sorted { $0.artist.localizedCompare($1.artist) == .orderedAscending }
        case .album:
            return baseList.sorted { $0.album.localizedCompare($1.album) == .orderedAscending }
        case .duration:
            return baseList.sorted { $0.duration < $1.duration }
        case .genre:
            return baseList.sorted { $0.genre.localizedCompare($1.genre) == .orderedAscending }
        case .dateAdded:
            return baseList.sorted { engine.getDateAdded(for: $0) > engine.getDateAdded(for: $1) }
        case .playCount:
            return baseList.sorted { engine.getPlayCount(for: $0) > engine.getPlayCount(for: $1) }
        }
    }
    
    var body: some View {
        Group {
            if engine.isMiniPlayer {
                MiniPlayerView(engine: engine)
            } else {
                ZStack {
                    if engine.enableSliceOfLifeTheme {
                        SliceOfLifeBackgroundView(engine: engine)
                    } else {
                        UniformDesign.bgMain(mode: engine.appearanceMode)
                            .ignoresSafeArea()
                    }
                    
                    // Main Window Content Layout
                    HStack(spacing: 0) {
                        // MARK: Sidebar Navigation
                        VStack(alignment: .leading, spacing: 20) {
                            // App Brand Header with Collapse Toggle Button
                            HStack(alignment: .center) {
                                if !engine.isSidebarCollapsed {
                                    HStack(spacing: 8) {
                                        Text("SAN")
                                            .font(.system(size: 20, weight: .bold, design: .default))
                                            .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                                            .tracking(3.5)
                                        
                                        Text("三")
                                            .font(.system(size: 14, weight: .light))
                                            .foregroundColor(engine.activeAccentColor)
                                    }
                                    
                                    Spacer(minLength: 0)
                                }
                                
                                Button(action: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        engine.isSidebarCollapsed.toggle()
                                        engine.saveLibrary()
                                    }
                                }) {
                                    Image(systemName: engine.isSidebarCollapsed ? "sidebar.right" : "sidebar.left")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                                        .frame(width: 32, height: 32)
                                        .background(
                                            Circle()
                                                .fill(UniformDesign.hoverHighlight(mode: engine.appearanceMode))
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help("Toggle Sidebar (Cmd+S)")
                            }
                            .frame(maxWidth: .infinity, alignment: engine.isSidebarCollapsed ? .center : .leading)
                            .padding(.horizontal, engine.isSidebarCollapsed ? 0 : 16)
                            .padding(.top, engine.isSidebarCollapsed ? 14 : 20)
                            .padding(.bottom, 6)
                            
                            // Grouped Sidebar Sections
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(alignment: engine.isSidebarCollapsed ? .center : .leading, spacing: 20) {
                                    // Section 1: LIBRARY
                                    SidebarSectionView(title: "LIBRARY", engine: engine) {
                                        SidebarNavItemButton(item: .library, engine: engine)
                                        SidebarNavItemButton(item: .albums, engine: engine)
                                        SidebarNavItemButton(item: .artists, engine: engine)
                                        SidebarNavItemButton(item: .nowPlaying, engine: engine)
                                        SidebarNavItemButton(item: .folders, engine: engine)
                                    }
                                    
                                    // Section 2: COLLECTIONS
                                    SidebarSectionView(title: "COLLECTIONS", engine: engine) {
                                        SidebarNavItemButton(item: .favorites, engine: engine)
                                        SidebarNavItemButton(item: .playlists, engine: engine)
                                    }
                                    
                                    // Section 3: SMART PLAYLISTS
                                    SidebarSectionView(title: "SMART PLAYLISTS", engine: engine) {
                                        SidebarNavItemButton(item: .recentlyAdded, engine: engine)
                                        SidebarNavItemButton(item: .mostPlayed, engine: engine)
                                        SidebarNavItemButton(item: .recentlyPlayed, engine: engine)
                                    }
                                    
                                    // Section 3: AUDIO & SYSTEM
                                    SidebarSectionView(title: "AUDIO & SYSTEM", engine: engine) {
                                        SidebarNavItemButton(item: .equalizer, engine: engine)
                                        SidebarNavItemButton(item: .settings, engine: engine)
                                    }
                                }
                                .padding(.horizontal, engine.isSidebarCollapsed ? 0 : 12)
                            }
                            
                            Spacer()
                            
                            // Quick Action Buttons
                            VStack(spacing: 8) {
                                Button(action: { engine.selectFolderToPlay() }) {
                                    HStack(spacing: engine.isSidebarCollapsed ? 0 : 8) {
                                        Image(systemName: "folder.fill")
                                            .font(.system(size: 13, weight: .semibold))
                                            .frame(width: 20, height: 20, alignment: .center)
                                        if !engine.isSidebarCollapsed {
                                            Text("Open Folder")
                                                .font(.system(size: 12, weight: .semibold))
                                                .lineLimit(1)
                                        }
                                    }
                                    .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(UniformDesign.hoverHighlight(mode: engine.appearanceMode))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .stroke(UniformDesign.borderSubtle(mode: engine.appearanceMode), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help("Open Folder")
                                
                                Button(action: { engine.openFiles() }) {
                                    HStack(spacing: engine.isSidebarCollapsed ? 0 : 8) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 13, weight: .semibold))
                                            .frame(width: 20, height: 20, alignment: .center)
                                        if !engine.isSidebarCollapsed {
                                            Text("Import Music")
                                                .font(.system(size: 12, weight: .semibold))
                                                .lineLimit(1)
                                        }
                                    }
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(engine.activeAccentColor)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help("Import Music")
                            }
                            .padding(.horizontal, engine.isSidebarCollapsed ? 12 : 14)
                            .padding(.bottom, 16)
                        }
                        .frame(width: engine.isSidebarCollapsed ? 68 : engine.sidebarWidth)
                        .frame(maxHeight: .infinity)
                        .background(
                            ZStack {
                                if engine.enableSidebarLiquidGlass || engine.enableSliceOfLifeTheme {
                                    NSVisualEffectBlurView(
                                        material: .hudWindow,
                                        blendingMode: .withinWindow,
                                        state: .active
                                    )
                                    (engine.appearanceMode == .light ? Color.white.opacity(0.08) : Color.black.opacity(0.12))
                                } else {
                                    UniformDesign.bgSidebar(mode: engine.appearanceMode)
                                }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(UniformDesign.borderSubtle(mode: engine.appearanceMode), lineWidth: 1)
                        )
                        .padding(.leading, 10)
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                        
                        // Draggable Sidebar Resize Handle
                        Rectangle()
                            .fill(UniformDesign.borderSubtle(mode: engine.appearanceMode))
                            .frame(width: 1)
                            .overlay(
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: 8)
                                    .contentShape(Rectangle())
                                    .gesture(
                                        DragGesture(minimumDistance: 1)
                                            .onChanged { value in
                                                let newWidth = engine.sidebarWidth + value.translation.width
                                                engine.sidebarWidth = min(280, max(160, newWidth))
                                            }
                                            .onEnded { _ in
                                                engine.saveLibrary()
                                            }
                                    )
                                    .onHover { hovering in
                                        if hovering {
                                            NSCursor.resizeLeftRight.push()
                                        } else {
                                            NSCursor.pop()
                                        }
                                    }
                            )
                        
                        // MARK: Main Content Workspace
                        VStack(spacing: 0) {
                            // Header Bar
                            HStack {
                                HStack(spacing: 10) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                                        .font(.system(size: 13))
                                    TextField("Search tracks, artists...", text: $engine.searchText)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                                        .font(.system(size: 13))
                                }
                                .padding(.vertical, 7)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(UniformDesign.hoverHighlight(mode: engine.appearanceMode))
                                )
                                .frame(maxWidth: 300)
                                
                                // Sort Picker
                                Picker("Sort", selection: $engine.currentSort) {
                                    ForEach(SortOption.allCases) { option in
                                        Text("Sort: \(option.rawValue)").tag(option)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(width: 130)
                                
                                Spacer()
                                
                                Button(action: { engine.toggleMiniPlayer() }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "rectangle.compress.vertical")
                                            .font(.system(size: 12))
                                        Text("Mini Player")
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(UniformDesign.hoverHighlight(mode: engine.appearanceMode)))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Text("\(engine.playlist.count) tracks")
                                    .font(.system(size: 12))
                                    .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 18)
                            .padding(.bottom, 16)
                            
                            // Main Scroll Area
                            ScrollView {
                                VStack(spacing: 24) {
                                    if engine.selectedNav == .equalizer {
                                        EqualizerView(engine: engine)
                                    } else if engine.selectedNav == .settings {
                                        SettingsView(engine: engine)
                                    } else if engine.selectedNav == .folders {
                                        FolderModeView(engine: engine)
                                    } else if engine.selectedNav == .albums {
                                        AlbumsGridView(engine: engine)
                                    } else if engine.selectedNav == .artists {
                                        ArtistsView(engine: engine)
                                    } else {
                                        if engine.selectedNav == .nowPlaying || engine.playlist.isEmpty {
                                            // Now Playing Stage with Hi-Res Badge & Lyrics Toggle
                                            ModernCard(cornerRadius: 14, mode: engine.appearanceMode) {
                                                if let track = engine.currentTrack {
                                                    HStack(alignment: .top, spacing: 28) {
                                                        // Artwork and Track Info
                                                        VStack(alignment: .leading, spacing: 14) {
                                                            ArtworkView(artwork: track.artwork, size: 160, isPlaying: engine.isPlaying, accentColor: engine.activeAccentColor, animationOption: engine.playerAnimation)
                                                            
                                                            VStack(alignment: .leading, spacing: 4) {
                                                                Text(track.title)
                                                                    .font(.system(size: 18, weight: .bold))
                                                                    .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                                                                    .lineLimit(2)
                                                                    .fixedSize(horizontal: false, vertical: true)
                                                                
                                                                Text(track.artist + (track.year.isEmpty ? "" : " • \(track.year)"))
                                                                    .font(.system(size: 13, weight: .medium))
                                                                    .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                                                                    .lineLimit(1)
                                                            }
                                                            
                                                            HStack(spacing: 8) {
                                                                // Hi-Res Audio Info Badge
                                                                Text(track.audioBadgeText)
                                                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                                                    .foregroundColor(engine.activeAccentColor)
                                                                    .padding(.horizontal, 8)
                                                                    .padding(.vertical, 4)
                                                                    .background(
                                                                        Capsule().fill(engine.activeAccentColor.opacity(0.12))
                                                                    )
                                                                
                                                                Spacer()
                                                                
                                                                // Inspect Info Button
                                                                Button(action: { engine.inspectingTrack = track }) {
                                                                    Image(systemName: "info.circle")
                                                                        .font(.system(size: 14, weight: .medium))
                                                                        .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                                                                        .padding(6)
                                                                }
                                                                .buttonStyle(PlainButtonStyle())
                                                                
                                                                // Lyrics Toggle Button
                                                                Button(action: { engine.toggleLyricsDisplay() }) {
                                                                    Image(systemName: engine.showLyrics ? "text.quote" : "text.alignleft")
                                                                        .font(.system(size: 14, weight: .medium))
                                                                        .foregroundColor(engine.showLyrics ? engine.activeAccentColor : UniformDesign.textMuted(mode: engine.appearanceMode))
                                                                        .padding(6)
                                                                        .background(Circle().fill(engine.showLyrics ? engine.activeAccentColor.opacity(0.15) : Color.clear))
                                                                }
                                                                .buttonStyle(PlainButtonStyle())
                                                                
                                                                // Favorite Heart Button
                                                                Button(action: { engine.toggleFavorite(track: track) }) {
                                                                    Image(systemName: engine.isFavorite(track: track) ? "heart.fill" : "heart")
                                                                        .font(.system(size: 16))
                                                                        .foregroundColor(engine.isFavorite(track: track) ? .red : UniformDesign.textMuted(mode: engine.appearanceMode))
                                                                        .padding(6)
                                                                }
                                                                .buttonStyle(PlainButtonStyle())
                                                            }
                                                            
                                                            ModernVisualizerView(levels: engine.visualizerLevels, accentColor: engine.activeAccentColor, style: engine.visualizerBarStyle)
                                                        }
                                                        .frame(minWidth: 260, maxWidth: engine.showLyrics ? 380 : .infinity, alignment: .leading)
                                                        
                                                        // Synced Lyrics Display Panel
                                                        if engine.showLyrics {
                                                            VStack(alignment: .leading, spacing: 10) {
                                                                HStack {
                                                                    Text("Lyrics")
                                                                        .font(.system(size: 13, weight: .bold))
                                                                    Spacer()
                                                                }
                                                                
                                                                if engine.currentLyrics.isEmpty {
                                                                    VStack {
                                                                        Spacer()
                                                                        Text("No synced lyrics found (.lrc file)")
                                                                            .font(.system(size: 12))
                                                                            .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
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
                                                                                        .font(.system(size: isActive ? 15 : 13, weight: isActive ? .bold : .regular))
                                                                                        .foregroundColor(isActive ? engine.activeAccentColor : UniformDesign.textMuted(mode: engine.appearanceMode))
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
                                                    }
                                                    .padding(24)
                                                } else {
                                                    VStack(spacing: 14) {
                                                        Image(systemName: "arrow.down.doc.fill")
                                                            .font(.system(size: 40, weight: .light))
                                                            .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                                                        Text("Drag & Drop Music Files Here")
                                                            .font(.system(size: 18, weight: .semibold))
                                                            .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                                                        Text("Or click 'Open Folder' to play music directly from any directory")
                                                            .font(.system(size: 13))
                                                            .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                                                        
                                                        HStack(spacing: 12) {
                                                            Button(action: { engine.selectFolderToPlay() }) {
                                                                Text("Open Folder")
                                                                    .font(.system(size: 13, weight: .semibold))
                                                                    .foregroundColor(.black)
                                                                    .padding(.horizontal, 20)
                                                                    .padding(.vertical, 8)
                                                                    .background(
                                                                        RoundedRectangle(cornerRadius: 8)
                                                                            .fill(engine.activeAccentColor)
                                                                    )
                                                            }
                                                            .buttonStyle(PlainButtonStyle())
                                                            
                                                            Button(action: { engine.openFiles() }) {
                                                                Text("Open Files")
                                                                    .font(.system(size: 13, weight: .semibold))
                                                                    .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                                                                    .padding(.horizontal, 20)
                                                                    .padding(.vertical, 8)
                                                                    .background(
                                                                        RoundedRectangle(cornerRadius: 8)
                                                                            .fill(UniformDesign.hoverHighlight(mode: engine.appearanceMode))
                                                                    )
                                                            }
                                                            .buttonStyle(PlainButtonStyle())
                                                        }
                                                    }
                                                    .padding(36)
                                                }
                                            }
                                            .padding(.horizontal, 24)
                                        }
                                        
                                        // Library List View
                                        ScrollViewReader { scrollProxy in
                                            VStack(alignment: .leading, spacing: 12) {
                                                // Header Title & Action Bar
                                                HStack {
                                                    let headerTitle: String = {
                                                        switch engine.selectedNav {
                                                        case .favorites: return "Favorite Tracks"
                                                        case .recentlyAdded: return "Recently Added Tracks"
                                                        case .mostPlayed: return "Most Played Tracks"
                                                        case .recentlyPlayed: return "Recently Played History"
                                                        default: return "Library Tracks"
                                                        }
                                                    }()
                                                    
                                                    Text(headerTitle)
                                                        .font(.system(size: 16, weight: .bold))
                                                        .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                                                    
                                                    Spacer()
                                                    
                                                    if engine.currentTrack != nil {
                                                        Button(action: {
                                                            if let current = engine.currentTrack {
                                                                withAnimation(.spring()) {
                                                                    scrollProxy.scrollTo(current.id, anchor: .center)
                                                                }
                                                            }
                                                        }) {
                                                            HStack(spacing: 6) {
                                                                Image(systemName: "location.fill")
                                                                    .font(.system(size: 11))
                                                                Text("Scroll to Playing")
                                                                    .font(.system(size: 11, weight: .semibold))
                                                            }
                                                            .foregroundColor(engine.activeAccentColor)
                                                            .padding(.horizontal, 10)
                                                            .padding(.vertical, 4)
                                                            .background(Capsule().fill(engine.activeAccentColor.opacity(0.12)))
                                                        }
                                                        .buttonStyle(PlainButtonStyle())
                                                    }
                                                }
                                                .padding(.horizontal, 24)
                                                
                                                if filteredPlaylist.isEmpty {
                                                    // Rich Empty State Card
                                                    VStack(spacing: 16) {
                                                        Image(systemName: engine.selectedNav == .favorites ? "heart.slash" : "music.note.house")
                                                            .font(.system(size: 44, weight: .light))
                                                            .foregroundColor(engine.activeAccentColor.opacity(0.8))
                                                            .padding(.top, 24)
                                                        
                                                        Text(engine.selectedNav == .favorites ? "No Favorites Yet" : "Your Music Library is Empty")
                                                            .font(.system(size: 16, weight: .bold))
                                                            .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                                                        
                                                        Text(engine.selectedNav == .favorites ? "Click the heart icon on any song to add it to your favorites." : "Drag and drop local audio files (MP3, WAV, FLAC, M4A) anywhere or click Import Music to populate your collection.")
                                                            .font(.system(size: 13))
                                                            .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                                                            .multilineTextAlignment(.center)
                                                            .frame(maxWidth: 420)
                                                        
                                                        if engine.selectedNav != .favorites {
                                                            Button(action: { engine.openFiles() }) {
                                                                HStack(spacing: 8) {
                                                                    Image(systemName: "square.and.arrow.down.fill")
                                                                        .font(.system(size: 13, weight: .semibold))
                                                                    Text("Import Audio Files")
                                                                        .font(.system(size: 13, weight: .bold))
                                                                }
                                                                .foregroundColor(.black)
                                                                .padding(.horizontal, 20)
                                                                .padding(.vertical, 10)
                                                                .background(Capsule().fill(engine.activeAccentColor))
                                                            }
                                                            .buttonStyle(PlainButtonStyle())
                                                            .padding(.bottom, 24)
                                                        }
                                                    }
                                                    .frame(maxWidth: .infinity)
                                                    .padding(32)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 16)
                                                            .fill(UniformDesign.bgCard(mode: engine.appearanceMode))
                                                            .overlay(
                                                                RoundedRectangle(cornerRadius: 16)
                                                                    .stroke(UniformDesign.borderSubtle(mode: engine.appearanceMode), lineWidth: 1)
                                                            )
                                                    )
                                                    .padding(.horizontal, 24)
                                                } else {
                                                    // Header Title & Action Bar
                                                    HStack {
                                                        Text(engine.activePlaylistTitle())
                                                            .font(.system(size: 16, weight: .bold))
                                                            .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                                                        
                                                        Spacer()
                                                        
                                                        if !filteredPlaylist.isEmpty {
                                                            Button(action: { engine.exportActivePlaylistM3U() }) {
                                                                HStack(spacing: 6) {
                                                                    Image(systemName: "square.and.arrow.up")
                                                                        .font(.system(size: 11, weight: .semibold))
                                                                    Text("Export .m3u8")
                                                                        .font(.system(size: 11, weight: .semibold))
                                                                }
                                                                .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                                                                .padding(.horizontal, 10)
                                                                .padding(.vertical, 5)
                                                                .background(
                                                                    Capsule()
                                                                        .fill(UniformDesign.hoverHighlight(mode: engine.appearanceMode))
                                                                        .overlay(
                                                                            Capsule().stroke(UniformDesign.borderSubtle(mode: engine.appearanceMode), lineWidth: 1)
                                                                        )
                                                                )
                                                            }
                                                            .buttonStyle(PlainButtonStyle())
                                                            
                                                            Button(action: { engine.syncActivePlaylistToUSB() }) {
                                                                HStack(spacing: 6) {
                                                                    Image(systemName: "externaldrive.fill.badge.plus")
                                                                        .font(.system(size: 11, weight: .semibold))
                                                                    Text("Sync to USB / DAP")
                                                                        .font(.system(size: 11, weight: .semibold))
                                                                }
                                                                .foregroundColor(.black)
                                                                .padding(.horizontal, 12)
                                                                .padding(.vertical, 5)
                                                                .background(Capsule().fill(engine.activeAccentColor))
                                                            }
                                                            .buttonStyle(PlainButtonStyle())
                                                        }
                                                    }
                                                    .padding(.horizontal, 24)
                                                    .padding(.bottom, 8)
                                                    
                                                    // Column Headers Bar
                                                    HStack(spacing: 14) {
                                                        Text("#")
                                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                            .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                                                            .frame(width: 24, alignment: .trailing)
                                                        
                                                        Spacer().frame(width: 32) // Artwork width offset
                                                        
                                                        Button(action: { engine.currentSort = .title }) {
                                                            HStack(spacing: 4) {
                                                                Text("TITLE & ARTIST")
                                                                if engine.currentSort == .title { Image(systemName: "chevron.down").font(.system(size: 9)) }
                                                            }
                                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                            .foregroundColor(engine.currentSort == .title ? engine.activeAccentColor : UniformDesign.textMuted(mode: engine.appearanceMode))
                                                        }
                                                        .buttonStyle(PlainButtonStyle())
                                                        
                                                        Spacer()
                                                        
                                                        Button(action: { engine.currentSort = .album }) {
                                                            HStack(spacing: 4) {
                                                                Text("ALBUM")
                                                                if engine.currentSort == .album { Image(systemName: "chevron.down").font(.system(size: 9)) }
                                                            }
                                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                            .foregroundColor(engine.currentSort == .album ? engine.activeAccentColor : UniformDesign.textMuted(mode: engine.appearanceMode))
                                                        }
                                                        .buttonStyle(PlainButtonStyle())
                                                        .frame(width: 130, alignment: .leading)
                                                        
                                                        Button(action: { engine.currentSort = .genre }) {
                                                            HStack(spacing: 4) {
                                                                Text("GENRE")
                                                                if engine.currentSort == .genre { Image(systemName: "chevron.down").font(.system(size: 9)) }
                                                            }
                                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                            .foregroundColor(engine.currentSort == .genre ? engine.activeAccentColor : UniformDesign.textMuted(mode: engine.appearanceMode))
                                                        }
                                                        .buttonStyle(PlainButtonStyle())
                                                        .frame(width: 90, alignment: .leading)
                                                        
                                                        Button(action: { engine.currentSort = .playCount }) {
                                                            HStack(spacing: 4) {
                                                                Text("PLAYS")
                                                                if engine.currentSort == .playCount { Image(systemName: "chevron.down").font(.system(size: 9)) }
                                                            }
                                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                            .foregroundColor(engine.currentSort == .playCount ? engine.activeAccentColor : UniformDesign.textMuted(mode: engine.appearanceMode))
                                                        }
                                                        .buttonStyle(PlainButtonStyle())
                                                        .frame(width: 50, alignment: .trailing)
                                                        
                                                        Button(action: { engine.currentSort = .duration }) {
                                                            HStack(spacing: 4) {
                                                                Text("TIME")
                                                                if engine.currentSort == .duration { Image(systemName: "chevron.down").font(.system(size: 9)) }
                                                            }
                                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                            .foregroundColor(engine.currentSort == .duration ? engine.activeAccentColor : UniformDesign.textMuted(mode: engine.appearanceMode))
                                                        }
                                                        .buttonStyle(PlainButtonStyle())
                                                        .frame(width: 45, alignment: .trailing)
                                                        
                                                        Spacer().frame(width: 28) // Action button spacing offset
                                                    }
                                                    .padding(.horizontal, 40)
                                                    .padding(.vertical, 4)
                                                    
                                                    VStack(spacing: 2) {
                                                        ForEach(Array(filteredPlaylist.enumerated()), id: \.element.id) { index, track in
                                                            let isHovered = engine.hoveredTrackId == track.id
                                                            let isSelected = engine.currentTrack == track
                                                            let plays = engine.getPlayCount(for: track)
                                                            
                                                            HStack(spacing: 14) {
                                                                Text("\(index + 1)")
                                                                    .font(.system(size: 12, design: .monospaced))
                                                                    .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                                                                    .frame(width: 24, alignment: .trailing)
                                                                
                                                                ArtworkView(artwork: track.artwork, size: 32)
                                                                
                                                                VStack(alignment: .leading, spacing: 2) {
                                                                    Text(track.title)
                                                                        .font(.system(size: 13, weight: .medium))
                                                                        .foregroundColor(isSelected ? engine.activeAccentColor : UniformDesign.textPrimary(mode: engine.appearanceMode))
                                                                        .lineLimit(1)
                                                                    Text(track.artist)
                                                                        .font(.system(size: 11))
                                                                        .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                                                                        .lineLimit(1)
                                                                }
                                                                
                                                                Spacer()
                                                                
                                                                Button(action: { engine.inspectingTrack = track }) {
                                                                    Image(systemName: "info.circle")
                                                                        .font(.system(size: 12))
                                                                        .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                                                                }
                                                                .buttonStyle(PlainButtonStyle())
                                                                
                                                                Button(action: { engine.toggleFavorite(track: track) }) {
                                                                    Image(systemName: engine.isFavorite(track: track) ? "heart.fill" : "heart")
                                                                        .font(.system(size: 12))
                                                                        .foregroundColor(engine.isFavorite(track: track) ? .red : UniformDesign.textMuted(mode: engine.appearanceMode))
                                                                }
                                                                .buttonStyle(PlainButtonStyle())
                                                                
                                                                Text(track.album)
                                                                    .font(.system(size: 12))
                                                                    .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                                                                    .frame(width: 130, alignment: .leading)
                                                                    .lineLimit(1)
                                                                
                                                                Text(track.genre.isEmpty ? "—" : track.genre)
                                                                    .font(.system(size: 11))
                                                                    .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                                                                    .frame(width: 90, alignment: .leading)
                                                                    .lineLimit(1)
                                                                
                                                                Text(plays > 0 ? "\(plays)x" : "—")
                                                                    .font(.system(size: 11, design: .monospaced))
                                                                    .foregroundColor(plays > 0 ? engine.activeAccentColor : UniformDesign.textMuted(mode: engine.appearanceMode))
                                                                    .frame(width: 50, alignment: .trailing)
                                                                
                                                                Text(formatTime(track.duration))
                                                                    .font(.system(size: 12, design: .monospaced))
                                                                    .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                                                                    .frame(width: 45, alignment: .trailing)
                                                                
                                                                Button(action: { engine.loadAndPlay(track: track) }) {
                                                                    Image(systemName: isSelected && engine.isPlaying ? "pause.fill" : "play.fill")
                                                                        .font(.system(size: 12))
                                                                        .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                                                                        .padding(6)
                                                                }
                                                                .buttonStyle(PlainButtonStyle())
                                                            }
                                                            .id(track.id)
                                                            .padding(.horizontal, 16)
                                                            .padding(.vertical, 6)
                                                            .background(
                                                                RoundedRectangle(cornerRadius: 8)
                                                                    .fill(isSelected ? UniformDesign.activeHighlight(mode: engine.appearanceMode) : (isHovered ? UniformDesign.hoverHighlight(mode: engine.appearanceMode) : Color.clear))
                                                            )
                                                            .contentShape(Rectangle())
                                                            .onTapGesture {
                                                                engine.loadAndPlay(track: track)
                                                            }
                                                            .onHover { hovering in
                                                                engine.hoveredTrackId = hovering ? track.id : nil
                                                            }
                                                            .contextMenu {
                                                                Button("Play Next") { engine.playNext(track: track) }
                                                                Button("Add to Queue") { engine.addToQueue(track: track) }
                                                                Button(engine.isFavorite(track: track) ? "Remove from Favorites" : "Add to Favorites") { engine.toggleFavorite(track: track) }
                                                                Button("Inspect File") { engine.inspectingTrack = track }
                                                                Divider()
                                                                Button("Remove from Library") { engine.removeTrack(track: track) }
                                                            }
                                                        }
                                                    }
                                                    .padding(.horizontal, 24)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            
                            // MARK: Bottom Player Bar
                            VStack(spacing: 8) {
                                Rectangle()
                                    .fill(UniformDesign.borderSubtle(mode: engine.appearanceMode))
                                    .frame(height: 1)
                                
                                // Scrubbing Progress Bar
                                HStack(spacing: 10) {
                                    Text(formatTime(engine.currentTime))
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                                    
                                    Slider(value: Binding(
                                        get: { engine.currentTime },
                                        set: { engine.seek(to: $0) }
                                    ), in: 0...max(1, engine.duration))
                                    .accentColor(engine.activeAccentColor)
                                    
                                    Text(formatTime(engine.duration))
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                                }
                                .padding(.horizontal, 20)
                                
                                // Transport Controls
                                HStack(spacing: 20) {
                                    // Current Song Info & Hi-Res Badge Preview (Click to open Now Playing with animation)
                                    HStack(spacing: 10) {
                                        ArtworkView(artwork: engine.currentTrack?.artwork, size: 36, isPlaying: engine.isPlaying, accentColor: engine.activeAccentColor, animationOption: engine.playerAnimation)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(engine.currentTrack?.title ?? "No Song Playing")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(UniformDesign.textPrimary(mode: engine.appearanceMode))
                                                .lineLimit(1)
                                            
                                            if let track = engine.currentTrack {
                                                Text(track.audioBadgeText)
                                                    .font(.system(size: 10, design: .monospaced))
                                                    .foregroundColor(engine.activeAccentColor)
                                                    .lineLimit(1)
                                            } else {
                                                Text("Select a track")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(UniformDesign.textSecondary(mode: engine.appearanceMode))
                                                    .lineLimit(1)
                                            }
                                        }
                                    }
                                    .frame(minWidth: 160, maxWidth: 260, alignment: .leading)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                            engine.selectedNav = .nowPlaying
                                        }
                                    }
                                    
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
                                    
                                    // Queue Drawer Button & Volume Slider
                                    HStack(spacing: 12) {
                                        Button(action: { engine.showQueueDrawer.toggle() }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "list.bullet.indent")
                                                    .font(.system(size: 12))
                                                if !engine.playQueue.isEmpty {
                                                    Text("\(engine.playQueue.count)")
                                                        .font(.system(size: 10, weight: .bold))
                                                        .foregroundColor(.black)
                                                        .padding(.horizontal, 5)
                                                        .padding(.vertical, 1)
                                                        .background(Capsule().fill(engine.activeAccentColor))
                                                }
                                            }
                                            .foregroundColor(engine.showQueueDrawer || !engine.playQueue.isEmpty ? engine.activeAccentColor : UniformDesign.textMuted(mode: engine.appearanceMode))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        HStack(spacing: 8) {
                                            Image(systemName: engine.volume == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                                .foregroundColor(UniformDesign.textMuted(mode: engine.appearanceMode))
                                                .font(.system(size: 12))
                                            
                                            Slider(value: $engine.volume, in: 0...1)
                                                .accentColor(engine.activeAccentColor)
                                                .frame(width: 80)
                                        }
                                    }
                                    .frame(minWidth: 160, maxWidth: 260, alignment: .trailing)
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 10)
                            }
                            .background(
                                ZStack {
                                    if engine.enableSidebarLiquidGlass || engine.enableSliceOfLifeTheme {
                                        NSVisualEffectBlurView(
                                            material: .hudWindow,
                                            blendingMode: .withinWindow,
                                            state: .active
                                        )
                                        (engine.appearanceMode == .light ? Color.white.opacity(0.08) : Color.black.opacity(0.12))
                                    } else {
                                        UniformDesign.bgBottomBar(mode: engine.appearanceMode)
                                    }
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(UniformDesign.borderSubtle(mode: engine.appearanceMode), lineWidth: 1)
                            )
                            .padding(.horizontal, 10)
                            .padding(.bottom, 10)
                            .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(minWidth: 780, maxWidth: .infinity, minHeight: 520, maxHeight: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(engine.isDropTargeted ? engine.activeAccentColor.opacity(0.6) : Color.clear, lineWidth: 3)
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
                .sheet(item: $engine.inspectingTrack) { track in
                    TrackInspectorView(track: track, engine: engine)
                }
                .sheet(isPresented: $engine.showQueueDrawer) {
                    PlayQueueDrawerSheet(engine: engine)
                }
                .sheet(isPresented: $engine.showSyncDrawer) {
                    USBSyncProgressSheet(engine: engine)
                }
                .onAppear {
                    // Shared AudioEngine reference for AppDelegate Status Bar HUD Popover
                    AppDelegate.sharedEngine = engine
                    
                    DispatchQueue.main.async {
                        if let window = NSApp.windows.first {
                            window.setFrameAutosaveName("SanMainWindow")
                        }
                    }
                    
                    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                        if let responder = NSApp.keyWindow?.firstResponder as? NSTextView, responder.isEditable {
                            return event
                        }
                        
                        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                        let keyCode = event.keyCode
                        
                        if flags.contains(.command) {
                            switch keyCode {
                            case 37: // Cmd + L -> Toggle Synced Lyrics
                                engine.toggleLyricsDisplay()
                                return nil
                            case 46: // Cmd + M -> Toggle Mini Player
                                engine.toggleMiniPlayer()
                                return nil
                            default:
                                break
                            }
                        } else if flags.isEmpty {
                            switch keyCode {
                            case 49: // Spacebar -> Toggle Play / Pause
                                engine.togglePlay()
                                return nil
                            case 123: // Left Arrow -> Seek -5s
                                engine.seek(to: max(0, engine.currentTime - 5.0))
                                return nil
                            case 124: // Right Arrow -> Seek +5s
                                engine.seek(to: min(engine.duration, engine.currentTime + 5.0))
                                return nil
                            default:
                                break
                            }
                        }
                        return event
                    }
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

// MARK: - App Delegate & Main Entry (Menu Bar Popover HUD)

class AppDelegate: NSObject, NSApplicationDelegate {
    static var sharedEngine: AudioEngine?
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
           let iconImg = NSImage(contentsOfFile: iconPath) {
            NSApp.applicationIconImage = iconImg
        }
        
        // Setup Status Bar Menu Item & Popover HUD
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        self.popover = popover
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "San")
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
    }
    
    @objc func statusBarButtonClicked() {
        guard let button = statusItem?.button else { return }
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else if let engine = AppDelegate.sharedEngine {
                popover.contentViewController = NSHostingController(rootView: StatusBarPopoverView(engine: engine))
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            } else {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first {
                    window.makeKeyAndOrderFront(nil)
                }
            }
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
