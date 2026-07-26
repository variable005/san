# San (三)

> San is a native, ultra-lightweight, 100% offline macOS local music player built with Swift and SwiftUI.

> [!WARNING]
> **Development Status**: San is currently under active development and may be unstable. Features, behavior, and build artifacts are subject to change.

---

## Overview

San (Japanese for Three / Harmony) provides a clean, modern interface for listening to local audio files without online accounts, telemetry, or external dependencies.

---

## Features

### Artist & Library Auto-Detection
- **Dedicated Artists Page**: Automatically groups tracks by artist with artist profile banners, total album counts, and total song counts.
- **Auto-Detected Albums**: Inspecting an artist page auto-detects and categorizes all albums belonging to that specific artist with cover artwork grids.
- **Play Artist Collection**: One-click action to play all tracks by an artist.

### Audio Visualizer & Motion Animations
- **7 Player Visualizer & Motion Options**: Selectable presentation options in Settings:
  1. **Fluid Spring**: Glowing artwork with responsive spring motion.
  2. **Vinyl Record Spin**: Rotating vinyl record disc with spindle & groove details.
  3. **Wave Spectrum Ring**: Animated audio frequency spectrum rings pulsing around circular artwork.
  4. **Floating Glass Card**: 3D tilted glassmorphic card with specular highlights.
  5. **Neon Aura Glow**: Multi-layered pulsing radial neon aura behind album art.
  6. **Gentle Ease**: Smooth ease-in-out breathing motion.
  7. **Snappy Fast**: Instant responsive scaling.

### Audio Engine & Playback
- **Crossfade Transitions**: Configurable overlap transition durations (Off, 1s, 2s, 3s, 5s) between tracks.
- **Pre-Buffered Gapless Playback**: Pre-loads next track buffers for zero-gap playback transitions.
- **5-Band Parametric Equalizer**: Custom audio processing with presets (Flat, Bass Boost, Treble Boost, Vocal, Electronic).
- **Play Count & History Tracking**: Automatically increments track play counts and tracks last-played dates.
- **Variable Playback Speed**: Control speed from 0.5x to 2.0x.
- **Stereo Balance Control**: Adjust left/right audio channel balance.
- **Synced LRC Lyrics**: Live lyric highlighting for `.lrc` sidecar files or embedded USLT ID3 metadata tags.

### Library & Smart Playlists
- **Smart Playlists**: Auto-generated dynamic views for Recently Added, Most Played (Top 25), and Recently Played tracks.
- **Sortable Column Headers**: Clickable column headers to sort library by Title, Artist, Album, Genre, Play Count, or Duration.
- **Genre & Release Year**: Metadata parsing and display across track rows and the Now Playing card.
- **Remove Tracks**: Context menu option to remove tracks from library and playlists.
- **Empty State Views**: Clear guidance and drag-and-drop landing states when collections are empty.
- **Scroll to Playing**: Instant jump button to highlight the active track in large libraries.

### Interface & Customization
- **Resizable Sidebar**: Drag-to-resize sidebar width (160pt to 280pt) with persisted dimensions.
- **Dynamic Album Artwork Color Extraction**: Samples dominant vibrant accent colors from playing album artwork in real time.
- **Appearance Modes**: Dark Mode, Pitch Black Mode (OLED), and Light Mode.
- **Window State Persistence**: Automatically restores exact window size and position on relaunch.
- **macOS Integration**: Menu bar popover HUD, Media key support, Now Playing Control Center integration, and Dock icon progress badge.

---

## Tech Stack

- **Language**: Swift 5.9
- **Framework**: SwiftUI + AppKit
- **Audio Core**: AVFoundation (AVAudioPlayer, AVURLAsset, CMAudioFormatDescription)
- **Control Center Integration**: MediaPlayer (MPRemoteCommandCenter, MPNowPlayingInfoCenter)

---

## Building from Source

```bash
./build.sh
```

The build script generates:
- Application binary: `dist/San.app`
- Installer package: `dist/San.dmg`

---

A project by Hariom Sharnam
