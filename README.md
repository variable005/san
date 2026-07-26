# San (三)

> San (三 — Japanese for Three / Harmony) is a native, ultra-lightweight, 100% offline macOS local music player built with Swift and SwiftUI.

> [!WARNING]
> **Development Status**: San is currently under active development and may be unstable. Features, behavior, and build specifications are subject to rapid change.

![macOS 13+](https://img.shields.io/badge/macOS-13.0%2B-black?style=flat-square)
![Swift 6](https://img.shields.io/badge/Swift-6.0-orange?style=flat-square)
![Size](https://img.shields.io/badge/App_Size-~360_KB-emerald?style=flat-square)
![Status](https://img.shields.io/badge/Status-In_Development-yellow?style=flat-square)
![Offline](https://img.shields.io/badge/Offline-100%25-blue?style=flat-square)

---

## Features

- **Ultra Lightweight (~360 KB)**: Built directly with native macOS frameworks (`SwiftUI`, `AppKit`, `AVFoundation`, `MediaPlayer`). Launches instantly in under 0.1 seconds with low memory footprint.
- **Hi-Res Audio Info Badge**: Displays real-time audio file specifications (sample rate, bit depth, format, bitrate e.g., `FLAC • 96.0kHz • 1411 kbps`).
- **Custom Accent Color Themes**: Choose from 5 minimalist accent highlight themes (*Minimalist White*, *Emerald*, *Sapphire*, *Crimson*, *Amber*) via the Settings tab.
- **Compact Mini-Player Mode**: Toggle a stay-on-top floating desktop widget.
- **Graphic Equalizer (EQ)**: 5-band frequency controls (60Hz, 230Hz, 910Hz, 3.6kHz, 14kHz) with presets (*Flat*, *Bass Boost*, *Treble Boost*, *Vocal*, *Electronic*).
- **Favorites System**: One-click heart toggle button to star tracks and filter dedicated favorite playlists.
- **Synced Real-Time Lyrics**: Automatically loads and parses `.lrc` timestamped lyrics files and highlights active singing lines in real-time.
- **Mac Media Keys and Hotkeys (`MPRemoteCommandCenter`)**: Hardware play/pause, next track, and previous track media key support on Mac keyboards.
- **macOS Control Center and Lock Screen Sync (`MPNowPlayingInfoCenter`)**: Live track title, artist name, album artwork, and progress bar synchronization in macOS Control Center and Lock Screen.
- **Drag and Drop File and Folder Import**: Drag `.mp3`, `.wav`, `.flac`, `.m4a`, or entire music folders directly from Finder into the application window to play instantly.
- **Persistent Library Storage**: Saves imported track paths to `~/Library/Application Support/San/library.json` so playlists and accent settings persist across application restarts.
- **Modern Dark Minimalist UI**: Matte dark background (`#141417`), 1px borders, high-contrast monochrome transport controls, and square artwork stage.
- **Real-Time Audio Visualizer**: Animated 16-band spectrum equalizer reflecting live audio output.
- **100% Offline and Private**: Zero network dependencies, zero tracking, zero login. Operates completely offline on local hardware.

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
