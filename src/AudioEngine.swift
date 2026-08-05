import SwiftUI
import AppKit
import AVFoundation
import MediaPlayer
import Combine
import CoreAudio

// MARK: - Audio Engine & App State Controller

class AudioEngine: NSObject, ObservableObject, AVAudioPlayerDelegate {
    // Audio Playback State
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 0.8 {
        didSet {
            audioPlayer?.volume = volume * sleepFadeVolumeFactor
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
    @Published var playlistFolders: [String] = []
    @Published var expandedFolders: Set<String> = []
    @Published var newTagText: String = ""
    @Published var currentSort: SortOption = .title
    @Published var newPlaylistName: String = ""
    @Published var showNewPlaylistPrompt: Bool = false
    @Published var selectedAlbum: AlbumGroup? = nil
    @Published var selectedArtist: ArtistGroup? = nil
    
    // Sleep Timer State
    @Published var sleepTimerMinutes: Int = 0 // 0 = off, 15, 30, 45, 60, -1 = end of track
    @Published var sleepTimerRemainingSeconds: Int = 0
    @Published var sleepFadeVolumeFactor: Float = 1.0
    private var sleepTimer: Timer?
    
    // Audio Output Switcher & Smart Autoplay State
    @Published var outputDevices: [AudioDevice] = []
    @Published var selectedDeviceUID: String? = nil
    @Published var isAutoplayEnabled: Bool = false
    
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
    @Published var activeFilterTag: String? = nil
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
        refreshOutputDevices()
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
            audioPlayer?.volume = (crossfadeDuration.seconds > 0 ? 0 : volume) * sleepFadeVolumeFactor
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
                        guard let self = self else { return }
                        let targetVol = self.volume * self.sleepFadeVolumeFactor
                        self.audioPlayer?.volume = min(targetVol, volumeStep * Float(i) * self.sleepFadeVolumeFactor)
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
    
    // MARK: - Smart Autoplay / Radio Recommendation Engine
    
    func findSimilarTrack(to currentTrack: Track) -> Track? {
        let candidates = playlist.filter { $0.id != currentTrack.id }
        guard !candidates.isEmpty else { return nil }
        
        let recentPaths = Set(recentlyPlayedTracks.prefix(15).map { $0.url.path })
        let unplayedCandidates = candidates.filter { !recentPaths.contains($0.url.path) }
        let pool = unplayedCandidates.isEmpty ? candidates : unplayedCandidates
        
        let currentTags = Set(getTags(for: currentTrack).map { $0.lowercased() })
        let currentArtist = currentTrack.artist.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let currentGenre = currentTrack.genre.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let currentAlbum = currentTrack.album.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        var bestTrack: Track? = nil
        var maxScore: Int = -1
        
        for track in pool {
            var score = 0
            
            // 1. Artist match (+40)
            let trackArtist = track.artist.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !trackArtist.isEmpty && trackArtist == currentArtist && currentArtist != "unknown artist" {
                score += 40
            }
            
            // 2. Genre match (+30)
            let trackGenre = track.genre.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !trackGenre.isEmpty && trackGenre == currentGenre {
                score += 30
            }
            
            // 3. Tag overlap (+15 per shared hashtag)
            let trackTags = Set(getTags(for: track).map { $0.lowercased() })
            let sharedTags = currentTags.intersection(trackTags)
            score += sharedTags.count * 15
            
            // 4. Album match (+10)
            let trackAlbum = track.album.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !trackAlbum.isEmpty && trackAlbum == currentAlbum && currentAlbum != "unknown album" {
                score += 10
            }
            
            score += Int.random(in: 0...5)
            
            if score > maxScore {
                maxScore = score
                bestTrack = track
            }
        }
        
        return bestTrack
    }
    
    func nextTrack() {
        // Priority 1: Up Next Play Queue
        if !playQueue.isEmpty {
            let next = playQueue.removeFirst()
            loadAndPlay(track: next)
            return
        }
        
        // Priority 2: Smart Autoplay Radio Mode when Queue is empty
        if isAutoplayEnabled, let current = currentTrack, let smartRec = findSimilarTrack(to: current) {
            loadAndPlay(track: smartRec)
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
    
    func currentTrackList() -> [Track] {
        var base: [Track] = []
        if selectedNav == .folders && !folderTracks.isEmpty {
            base = folderTracks
        } else if selectedNav == .favorites {
            base = playlist.filter { isFavorite(track: $0) }
        } else if selectedNav == .playlists, let id = activePlaylistId, let pl = userPlaylists.first(where: { $0.id == id }) {
            let paths = Set(pl.trackPaths)
            base = playlist.filter { paths.contains($0.url.path) }
        } else if selectedNav == .recentlyAdded {
            base = recentlyAddedTracks
        } else if selectedNav == .mostPlayed {
            base = mostPlayedTracks
        } else if selectedNav == .recentlyPlayed {
            base = recentlyPlayedTracks
        } else {
            base = playlist
        }
        
        if let filterTag = activeFilterTag {
            base = base.filter { track in
                let tags = getTags(for: track)
                return tags.contains(filterTag)
            }
        }
        
        return base
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
    
    func toggleFolderExpanded(_ folder: String) {
        if expandedFolders.contains(folder) {
            expandedFolders.remove(folder)
        } else {
            expandedFolders.insert(folder)
        }
    }
    
    func movePlaylist(_ playlist: UserPlaylist, toFolder folder: String?) {
        if let index = userPlaylists.firstIndex(where: { $0.id == playlist.id }) {
            userPlaylists[index].folderName = folder
            saveLibrary()
        }
    }
    
    func renamePlaylist(_ playlist: UserPlaylist, newName: String) {
        let clean = newName.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty else { return }
        if let index = userPlaylists.firstIndex(where: { $0.id == playlist.id }) {
            userPlaylists[index].name = clean
            saveLibrary()
        }
    }
    
    func createFolder(name: String) {
        let clean = name.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty else { return }
        if !playlistFolders.contains(clean) {
            playlistFolders.append(clean)
            playlistFolders.sort()
            saveLibrary()
        }
    }
    
    func renameFolder(_ oldName: String, newName: String) {
        let clean = newName.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty, clean != oldName else { return }
        
        // Update folder list
        if let index = playlistFolders.firstIndex(of: oldName) {
            playlistFolders[index] = clean
            playlistFolders.sort()
        }
        
        // Update all playlists in this folder
        for i in 0..<userPlaylists.count {
            if userPlaylists[i].folderName == oldName {
                userPlaylists[i].folderName = clean
            }
        }
        
        // Update expansion set
        if expandedFolders.contains(oldName) {
            expandedFolders.remove(oldName)
            expandedFolders.insert(clean)
        }
        
        saveLibrary()
    }
    
    func deleteFolder(_ folder: String, keepPlaylists: Bool) {
        playlistFolders.removeAll(where: { $0 == folder })
        expandedFolders.remove(folder)
        
        if keepPlaylists {
            for i in 0..<userPlaylists.count {
                if userPlaylists[i].folderName == folder {
                    userPlaylists[i].folderName = nil
                }
            }
        } else {
            // Delete all playlists inside
            let playlistsToDelete = userPlaylists.filter { $0.folderName == folder }
            userPlaylists.removeAll(where: { $0.folderName == folder })
            for pl in playlistsToDelete {
                if activePlaylistId == pl.id {
                    activePlaylistId = userPlaylists.first?.id
                }
            }
        }
        
        saveLibrary()
    }
    
    // Prompts
    func promptCreatePlaylist() {
        let alert = NSAlert()
        alert.messageText = "Create New Playlist"
        alert.informativeText = "Enter a name for the new playlist:"
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        input.placeholderString = "Playlist Name"
        alert.accessoryView = input
        
        if alert.runModal() == .alertFirstButtonReturn {
            let name = input.stringValue.trimmingCharacters(in: .whitespaces)
            if !name.isEmpty {
                self.createPlaylist(name: name)
            }
        }
    }
    
    func promptCreateFolder() {
        let alert = NSAlert()
        alert.messageText = "Create New Folder"
        alert.informativeText = "Enter a name for the new playlist folder:"
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        input.placeholderString = "Folder Name"
        alert.accessoryView = input
        
        if alert.runModal() == .alertFirstButtonReturn {
            let name = input.stringValue.trimmingCharacters(in: .whitespaces)
            if !name.isEmpty {
                self.createFolder(name: name)
            }
        }
    }
    
    func promptRenamePlaylist(_ playlist: UserPlaylist) {
        let alert = NSAlert()
        alert.messageText = "Rename Playlist"
        alert.informativeText = "Enter a new name for '\(playlist.name)':"
        alert.addButton(withTitle: "Rename")
        alert.addButton(withTitle: "Cancel")
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        input.stringValue = playlist.name
        alert.accessoryView = input
        
        if alert.runModal() == .alertFirstButtonReturn {
            let name = input.stringValue.trimmingCharacters(in: .whitespaces)
            if !name.isEmpty {
                self.renamePlaylist(playlist, newName: name)
            }
        }
    }
    
    func promptRenameFolder(_ oldName: String) {
        let alert = NSAlert()
        alert.messageText = "Rename Folder"
        alert.informativeText = "Enter a new name for '\(oldName)':"
        alert.addButton(withTitle: "Rename")
        alert.addButton(withTitle: "Cancel")
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        input.stringValue = oldName
        alert.accessoryView = input
        
        if alert.runModal() == .alertFirstButtonReturn {
            let name = input.stringValue.trimmingCharacters(in: .whitespaces)
            if !name.isEmpty {
                self.renameFolder(oldName, newName: name)
            }
        }
    }
    
    func promptMovePlaylistToNewFolder(_ playlist: UserPlaylist) {
        let alert = NSAlert()
        alert.messageText = "Move to New Folder"
        alert.informativeText = "Enter a name for the new folder:"
        alert.addButton(withTitle: "Move")
        alert.addButton(withTitle: "Cancel")
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        input.placeholderString = "Folder Name"
        alert.accessoryView = input
        
        if alert.runModal() == .alertFirstButtonReturn {
            let name = input.stringValue.trimmingCharacters(in: .whitespaces)
            if !name.isEmpty {
                self.createFolder(name: name)
                self.movePlaylist(playlist, toFolder: name)
            }
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
            var customPaths: [String] = []
            
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
                    customPaths.append(fileName)
                } catch {
                    print("Error copying track \(track.title): \(error.localizedDescription)")
                }
            }
            
            // Create relative .m3u8 playlist on the USB drive matching custom filenames
            if let manager = self {
                let m3uContent = PlaylistSyncManager.shared.generateM3UContent(tracks: copiedTracks, customPaths: customPaths)
                let m3uPath = destinationFolder.appendingPathComponent("\(safeName).m3u8")
                do {
                    try m3uContent.write(to: m3uPath, atomically: true, encoding: .utf8)
                } catch {
                    print("Failed to write synced playlist file: \(error.localizedDescription)")
                }
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
        
        if minutes <= 0 {
            sleepFadeVolumeFactor = 1.0
            audioPlayer?.volume = volume
        }
        
        if minutes > 0 {
            sleepTimerRemainingSeconds = minutes * 60
            sleepFadeVolumeFactor = 1.0
            sleepTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                if self.sleepTimerRemainingSeconds > 0 {
                    self.sleepTimerRemainingSeconds -= 1
                    
                    // Linear fade out in the last 60 seconds
                    if self.sleepTimerRemainingSeconds <= 60 {
                        let factor = Float(self.sleepTimerRemainingSeconds) / 60.0
                        self.sleepFadeVolumeFactor = factor
                        self.audioPlayer?.volume = self.volume * factor
                    } else {
                        self.sleepFadeVolumeFactor = 1.0
                    }
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
    
    // MARK: - Tagging System
    
    func getTags(for track: Track) -> [String] {
        return trackStats[track.url.path]?.tags ?? []
    }
    
    func addTag(_ tag: String, to track: Track) {
        let clean = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        
        let path = track.url.path
        if trackStats[path] == nil {
            trackStats[path] = TrackStats(playCount: 0, lastPlayedDate: nil, dateAdded: Date(), tags: [])
        }
        
        if trackStats[path]?.tags == nil {
            trackStats[path]?.tags = []
        }
        
        if !(trackStats[path]?.tags?.contains(clean) ?? false) {
            trackStats[path]?.tags?.append(clean)
            saveTrackStats()
            objectWillChange.send() // Force UI updates
        }
    }
    
    func removeTag(_ tag: String, from track: Track) {
        let path = track.url.path
        if trackStats[path]?.tags != nil {
            trackStats[path]?.tags?.removeAll(where: { $0 == tag })
            saveTrackStats()
            objectWillChange.send() // Force UI updates
        }
    }
    
    func allTags() -> [String] {
        var tagsSet = Set<String>()
        for stats in trackStats.values {
            if let tags = stats.tags {
                for t in tags {
                    let trimmed = t.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        tagsSet.insert(trimmed)
                    }
                }
            }
        }
        return Array(tagsSet).sorted()
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
            playlistFolders: playlistFolders,
            lastFolderURL: selectedFolderURL?.path,
            sidebarWidth: sidebarWidth,
            crossfadeDuration: crossfadeDuration,
            enableSliceOfLifeTheme: enableSliceOfLifeTheme,
            enableSidebarLiquidGlass: enableSidebarLiquidGlass,
            isSidebarCollapsed: isSidebarCollapsed,
            selectedDeviceUID: selectedDeviceUID,
            isAutoplayEnabled: isAutoplayEnabled
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
            if let folders = savedData.playlistFolders {
                self.playlistFolders = folders
            } else {
                let unique = Array(Set(self.userPlaylists.compactMap { $0.folderName })).sorted()
                self.playlistFolders = unique
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
            if let dev = savedData.selectedDeviceUID {
                self.selectedDeviceUID = dev
            }
            if let auto = savedData.isAutoplayEnabled {
                self.isAutoplayEnabled = auto
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
    
    // MARK: - CoreAudio Device Querying & Switcher
    
    func getSystemDefaultOutputDeviceUID() -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var deviceID: AudioDeviceID = 0
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        
        guard status == noErr else { return nil }
        
        var uidAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var uidCF: Unmanaged<CFString>?
        var uidSize = UInt32(MemoryLayout<CFString?>.size)
        AudioObjectGetPropertyData(deviceID, &uidAddress, 0, nil, &uidSize, &uidCF)
        
        return uidCF?.takeRetainedValue() as String?
    }
    
    func refreshOutputDevices() {
        var devices: [AudioDevice] = []
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize
        )
        
        guard status == noErr else { return }
        
        let deviceCount = Int(dataSize) / MemoryLayout<AudioObjectID>.size
        var deviceIDs = [AudioObjectID](repeating: 0, count: deviceCount)
        
        let status2 = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &deviceIDs
        )
        
        guard status2 == noErr else { return }
        
        for deviceID in deviceIDs {
            var streamAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreams,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            
            var streamSize: UInt32 = 0
            let streamStatus = AudioObjectGetPropertyDataSize(
                deviceID,
                &streamAddress,
                0,
                nil,
                &streamSize
            )
            
            guard streamStatus == noErr && streamSize > 0 else { continue }
            
            var nameAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceNameCFString,
                mScope: kAudioObjectPropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            
            var nameCF: Unmanaged<CFString>?
            var nameSize = UInt32(MemoryLayout<CFString?>.size)
            AudioObjectGetPropertyData(deviceID, &nameAddress, 0, nil, &nameSize, &nameCF)
            
            var uidAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceUID,
                mScope: kAudioObjectPropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            
            var uidCF: Unmanaged<CFString>?
            var uidSize = UInt32(MemoryLayout<CFString?>.size)
            AudioObjectGetPropertyData(deviceID, &uidAddress, 0, nil, &uidSize, &uidCF)
            
            if let name = nameCF?.takeRetainedValue() as String?,
               let uid = uidCF?.takeRetainedValue() as String? {
                devices.append(AudioDevice(name: name, uid: uid, deviceID: deviceID))
            }
        }
        
        DispatchQueue.main.async {
            self.outputDevices = devices
            if let selected = self.selectedDeviceUID {
                if !devices.contains(where: { $0.uid == selected }) {
                    self.selectedDeviceUID = nil
                }
            }
        }
    }
    
    func setOutputDevice(uid: String?) {
        guard let targetUID = uid else {
            self.selectedDeviceUID = nil
            self.saveLibrary()
            return
        }
        
        guard let device = outputDevices.first(where: { $0.uid == targetUID }) else { return }
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var devID = device.deviceID
        let size = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            size,
            &devID
        )
        
        if status == noErr {
            self.selectedDeviceUID = targetUID
            self.saveLibrary()
            self.objectWillChange.send()
        } else {
            print("Failed to set default output device: \(status)")
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
