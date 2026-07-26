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

### Dynamic Themes, Appearance & Player Animations
- **🎨 Dynamic Album Artwork Theme Extraction**: Samples vibrant dominant accent colors directly from playing album cover art (`NSBitmapImageRep` pixel analysis) and dynamically morphs visualizer bars, sliders, and glowing shadows in real time.
- **✨ Player Animation Options**: Choose your preferred motion style and artwork presentation in Settings:
  - **Fluid Spring**: Smooth bouncy fluid spring transitions.
  - **Vinyl Record Spin**: Artwork presents as an authentic rotating vinyl disc with center spindle hole, grooves, and 60fps spin animation.
  - **Gentle Ease**: Soft, elegant ease-in-out transitions.
  - **Snappy Fast**: Ultra-snappy, linear instant response.
- **Appearance Modes (Settings)**:
  - **Dark Mode**: Standard matte dark aesthetic (`#141417`).
  - **Pitch Black Mode**: Pure black OLED mode (`#000000`) for battery savings and high contrast.
  - **Light Mode**: High-contrast, clean minimalist light theme (`#F6F6F8`).

### Menu Bar Popover HUD & Visualizer
- **🎯 macOS Menu Bar Live HUD**: Click the **San** status bar icon in your Mac's Menu Bar to reveal a popup HUD popover with:
  - Live album cover art, track title, artist, and Hi-Res audio specifications badge.
  - Live spectrum visualizer frequency bars.
  - Play/Pause, Next, Previous transport control buttons.
  - Quick "Open San" button to bring the main window to front.

### Audiophile Equalizer and Hardware Controls
- **🎛️ Redesigned Graphic Equalizer (EQ)**: Hardware-style vertical fader controls with center `0dB` midpoint markers, exact `+12dB` to `-12dB` gain meters, 1-click **Reset EQ** button, and active frequency fader fills.
- **EQ Presets**: *Flat*, *Bass Boost*, *Treble Boost*, *Vocal*, *Electronic*.
- **Hi-Res Audio Info Badge**: Displays real-time audio specifications (sample rate, bit depth, format, bitrate e.g., `FLAC • 96.0kHz • 1411 kbps`).
- **Variable Playback Speed**: 0.5x, 0.75x, 1.0x, 1.25x, 1.5x, and 2.0x playback rate selector.
- **Stereo Balance (Pan Control)**: Fine-tuned Left/Right channel audio balance slider.
- **Synced Real-Time Lyrics**: Automatically loads `.lrc` timestamped lyrics files and highlights active singing lines in real-time.

### Up Next Play Queue and Album Grid
- **📜 Up Next Play Queue**: Right-click or tap any track to select **Play Next** or **Add to Queue**. Queued songs play with highest priority.
- **Queue Drawer Panel**: View upcoming queued tracks, remove items, or clear the queue from the bottom player bar (with active queue badge counter).
- **🎨 Visual Album Grid View**: Browse library tracks grouped into responsive high-resolution album cover cards (`Albums` tab). Click an album to view its tracks or play the entire album.

### Keyboard Shortcuts and Controls
- **⌨️ In-App Global Keyboard Shortcuts**:
  - `Spacebar`: Toggle Play / Pause
  - `Left Arrow` (`←`): Seek backward 5 seconds
  - `Right Arrow` (`→`): Seek forward 5 seconds
  - `Cmd + L`: Toggle Synced Lyrics panel
  - `Cmd + M`: Toggle Mini-Player mode
- **Mac Media Keys and Hotkeys**: Full hardware play/pause, next track, and previous track media key support on Apple keyboards (`MPRemoteCommandCenter`).

### Playback, Library, and Storage
- **Folder Mode (Select Folder to Play)**: Select any directory (`~/Music`, external drives, or custom folders) to browse and play audio files strictly within that folder structure.
- **Sleep Timer**: Auto-stop playback countdown timer (15m, 30m, 45m, 60m, or end of track).
- **Custom Playlists**: Create, rename, and add/remove tracks from custom playlists.
- **Track Inspector**: View detailed offline file metadata (file size, channel count, sample rate, bit depth, format, exact path).
- **Favorites System**: One-click heart button to star tracks and filter dedicated favorite playlists.
- **Drag and Drop Import**: Drag audio files or folders from Finder directly into the application window.
- **Persistent Storage**: Saves imported track paths to `~/Library/Application Support/San/library.json` so playlists, last folder path, theme settings, appearance mode, and animation options persist across restarts.

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
