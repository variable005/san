import SwiftUI
import AppKit

// MARK: - Data Models

struct AudioDevice: Identifiable, Equatable, Codable {
    var id: String { uid }
    let name: String
    let uid: String
    let deviceID: UInt32
}

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
    var tags: [String]?
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
    var folderName: String?
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
    var playlistFolders: [String]?
    var lastFolderURL: String?
    var windowFrame: [CGFloat]?
    var sidebarWidth: CGFloat?
    var crossfadeDuration: CrossfadeDuration?
    var enableSliceOfLifeTheme: Bool?
    var enableSidebarLiquidGlass: Bool?
    var isSidebarCollapsed: Bool?
    var selectedDeviceUID: String?
    var isAutoplayEnabled: Bool?
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
