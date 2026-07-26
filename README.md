# San (三)

> San (三 — Japanese for Three / Harmony) is a native, ultra-lightweight, 100% offline macOS local music player built with Swift and SwiftUI.

> [!WARNING]
> **Development Status**: San is currently under active development and may be unstable. Features, behavior, and build specifications are subject to rapid change.

---

## Features

### Performance and Architecture
- **Ultra Lightweight (~360 KB)**: Built natively with `SwiftUI`, `AppKit`, `AVFoundation`, and `MediaPlayer`. Launches instantly with a low memory footprint.
- **100% Offline and Private**: Zero network dependencies, zero tracking, zero telemetry, zero login. All metadata parsing and audio processing take place strictly on local hardware.
- **Apple Silicon Native**: Compiled directly to `arm64` machine code for M-series Mac processors.

### Folder Mode and Directory Playback
- **Select Folder to Play (Folder Browser)**: Select any folder on disk (`~/Music`, external drives, or custom folders) to browse and play audio files strictly within that directory structure.
- **Auto-Scan Subdirectories**: Recursively scans folders for `.mp3`, `.wav`, `.flac`, `.m4a`, and `.aac` tracks.

### Audiophile and Audio Controls
- **Hi-Res Audio Info Badge**: Displays real-time audio specifications (sample rate, bit depth, format, bitrate e.g., `FLAC • 96.0kHz • 1411 kbps`).
- **Graphic Equalizer (EQ)**: 5-band frequency control (60Hz, 230Hz, 910Hz, 3.6kHz, 14kHz) with presets (*Flat*, *Bass Boost*, *Treble Boost*, *Vocal*, *Electronic*).
- **Variable Playback Speed**: 0.5x, 0.75x, 1.0x, 1.25x, 1.5x, and 2.0x playback rate selector.
- **Stereo Balance (Pan Control)**: Fine-tuned Left/Right channel audio balance slider.
- **Synced Real-Time Lyrics**: Automatically loads `.lrc` timestamped lyrics files and highlights active singing lines in real-time.

### Playback, Library, and Storage
- **Sleep Timer**: Auto-stop playback countdown timer (15m, 30m, 45m, 60m, or end of track).
- **Custom Playlists**: Create, rename, and add/remove tracks from custom playlists.
- **Track Inspector**: View detailed offline file metadata (file size, channel count, sample rate, exact path).
- **Favorites System**: One-click heart button to star tracks and filter dedicated favorite playlists.
- **Drag and Drop Import**: Drag audio files or folders from Finder directly into the application window.
- **Persistent Storage**: Saves imported track paths to `~/Library/Application Support/San/library.json` so playlists, last folder path, and theme settings persist across restarts.

### macOS Integration and Interface
- **Mac Media Keys and Hotkeys**: Full hardware play/pause, next track, and previous track media key support on Apple keyboards (`MPRemoteCommandCenter`).
- **macOS Control Center and Lock Screen Sync**: Live track title, artist name, artwork, and progress bar sync (`MPNowPlayingInfoCenter`).
- **Compact Mini-Player Mode**: Press `Cmd + M` to toggle a stay-on-top floating desktop widget.
- **Custom Accent Color Themes**: Select from 5 minimalist accent themes (*Minimalist White*, *Emerald*, *Sapphire*, *Crimson*, *Amber*) in the Settings tab.
- **Modern Dark Minimalist UI**: Matte dark background (`#141417`), 1px borders, high-contrast monochrome controls, and real-time audio visualizer.

---

## Building from Source

### Prerequisites
- macOS 13.0 or later
- Swift 6.0 or later (Command Line Tools)

### Build Command

Clone the repository and run the build script:

```bash
git clone https://github.com/variable005/san.git
cd san
./build.sh
```

The build script compiles `src/main.swift` using `swiftc` and generates two output files in `dist/`:
- `dist/San.app` (Native macOS Application)
- `dist/San.dmg` (Mountable Disk Image Installer)

---

## Installation

1. Download or build `San.dmg`.
2. Double-click `San.dmg` to mount the disk image.
3. Drag **San** into your `/Applications` folder.

Alternatively, launch directly via terminal:
```bash
open dist/San.app
```

---

## Repository Structure

```
san/
├── src/
│   └── main.swift       # Swift & SwiftUI application source code
├── build/
│   └── Info.plist       # macOS App Bundle property list
├── build.sh             # Build script for compiling app & packaging DMG
├── .gitignore
└── README.md
```
