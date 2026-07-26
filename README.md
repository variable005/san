# San (三)

> San is a native, ultra-lightweight, 100% offline macOS local music player built with Swift and SwiftUI.

> [!WARNING]
> **Development Status**: San is currently under active development and may be unstable. Features, behavior, and build specifications are subject to rapid change.

---

## Overview

San is designed for Mac users who prioritize audio privacy, instant startup performance, and refined desktop aesthetics. Built natively for macOS using Apple's Swift language and AVFoundation audio framework, San operates strictly offline with zero network requests, tracking, or background telemetry.

---

## Features

### Performance and Architecture
- **Ultra Lightweight (~360 KB)**: Built natively with SwiftUI, AppKit, AVFoundation, and MediaPlayer. Launches instantly with minimal system resource utilization.
- **100% Offline and Private**: Zero network dependencies, zero analytics, zero telemetry, and zero account registration. All metadata parsing and audio processing occur locally on your Mac.
- **Apple Silicon Native**: Compiled directly for arm64 architecture, optimized for Apple M-series processors.

### Symmetrical Interface & Customization
- **Categorized Sidebar Navigation**: Organized into Library, Collections, and Audio & System sections with a fixed 20pt icon grid for precise vertical text alignment.
- **Dynamic Album Artwork Color Extraction**: Automatically samples dominant vibrant accent colors from playing album artwork to dynamically theme visualizer bars, sliders, and glowing UI elements in real time.
- **Custom Player Animation Styles**: Selectable motion options in Settings, including Fluid Spring, Vinyl Record Spin, Gentle Ease, and Snappy Fast.
- **Appearance Modes**:
  - Dark Mode: Standard matte dark interface.
  - Pitch Black Mode: Pure black OLED theme for maximum contrast and power efficiency.
  - Light Mode: High-contrast, clean minimalist light theme.

### Audio Processing and Audiophile Controls
- **Graphic Equalizer (EQ)**: 5-band vertical fader control (60Hz, 230Hz, 910Hz, 3.6kHz, 14kHz) with hardware-style center 0dB midpoint indicators and exact gain readout meters (-12.0dB to +12.0dB).
- **Equalizer Presets**: Flat, Bass Boost, Treble Boost, Vocal, Electronic, and a 1-click Reset EQ action.
- **Hi-Res Audio Info Badge**: Displays real-time audio sample rate, bit depth, format, and bitrate (for example, FLAC • 96.0kHz • 1411 kbps).
- **Variable Playback Speed**: 0.5x, 0.75x, 1.0x, 1.25x, 1.5x, and 2.0x playback rate controls.
- **Stereo Balance**: Fine-tuned Left/Right channel panning control.
- **Synced LRC Lyrics**: Parses timestamped .lrc files and automatically highlights active singing lines during playback.

### Playback Queue and Library Management
- **Up Next Play Queue**: Right-click or tap any track to choose Play Next or Add to Queue. Dedicated drawer panel allows reordering and clearing queued tracks.
- **Visual Album Artwork Grid**: Browse library tracks grouped into responsive high-resolution album cover cards with dedicated album detail views.
- **Folder Mode**: Browse and play audio files directly from any folder directory or external drive without altering file structures.
- **Custom Playlists & Favorites**: Create, rename, and manage custom playlists and starred favorite tracks.
- **Track Inspector**: View comprehensive metadata, including file size, channel count, sample rate, bit depth, format, and exact file path.

### macOS Integration and Keyboard Control
- **In-App Keyboard Shortcuts**:
  - Spacebar: Toggle Play / Pause
  - Left Arrow: Seek backward 5 seconds
  - Right Arrow: Seek forward 5 seconds
  - Cmd + L: Toggle Synced Lyrics panel
  - Cmd + M: Toggle Compact Mini-Player
- **macOS Menu Bar Popover HUD**: Click the status bar icon to access live artwork, spectrum visualizer bars, and transport controls from any desktop workspace.
- **Control Center and Media Keys**: Native integration with hardware media keys (Play, Pause, Next, Prev) and System Now Playing information.

---

## Supported Formats

- FLAC (Free Lossless Audio Codec)
- WAV (Waveform Audio File Format)
- MP3 (MPEG-1 Audio Layer III)
- M4A / AAC (Advanced Audio Coding)

---

## Building from Source

### Prerequisites
- macOS 13.0 or later
- Swift 6.0 or later (Xcode Command Line Tools)

### Build Command

Clone the repository and run the build script:

```bash
git clone https://github.com/variable005/san.git
cd san
./build.sh
```

The build script compiles `src/main.swift` using `swiftc` and generates two distribution packages in `dist/`:
- `dist/San.app` (Native macOS Application)
- `dist/San.dmg` (Disk Image Installer)

---

## Installation

1. Mount `San.dmg`.
2. Drag **San** into your `/Applications` directory.
3. Launch San from Launchpad or Terminal:
   ```bash
   open /Applications/San.app
   ```

---

## Repository Structure

```
san/
├── src/
│   └── main.swift       # Application source code (Swift & SwiftUI)
├── build/
│   └── Info.plist       # macOS App Bundle property list
├── build.sh             # Build and packaging script
├── .gitignore
└── README.md
```

---

A project by Hariom Sharnam
