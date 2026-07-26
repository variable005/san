# San (三) 

> **San** (三 — Japanese for *Three / Harmony*) is a native, ultra-lightweight, 100% offline macOS local music player built with Swift & SwiftUI.

![macOS 13+](https://img.shields.io/badge/macOS-13.0%2B-black?style=for-the-badge&logo=apple)
![Swift 6](https://img.shields.io/badge/Swift-6.0-orange?style=for-the-badge&logo=swift)
![Size](https://img.shields.io/badge/App_Size-~340_KB-emerald?style=for-the-badge)
![Offline](https://img.shields.io/badge/Offline-100%25-blue?style=for-the-badge)

---

## ✨ Features

- **⚡ Ultra Lightweight (~340 KB)**: Built directly with Apple's native frameworks (`SwiftUI`, `AppKit`, `AVFoundation`, `MediaPlayer`). Launches instantly in under 0.1 seconds with near-zero memory footprint.
- **🎹 Mac Media Keys & Hotkeys (`MPRemoteCommandCenter`)**: Full hardware play/pause, next track, and previous track media key support on your Mac keyboard.
- **📱 macOS Control Center & Lock Screen Sync (`MPNowPlayingInfoCenter`)**: Live track title, artist name, album artwork, and progress bar synchronization in macOS Control Center and Lock Screen.
- **📂 Drag & Drop File & Folder Import**: Drag any `.mp3`, `.wav`, `.flac`, `.m4a`, or entire music folders directly from Finder into the app window to play instantly.
- **💾 Persistent Library Storage**: Saves imported track paths to `~/Library/Application Support/San/library.json` so your playlist persists across app restarts.
- **🎨 Modern Dark Minimalist UI**: Clean matte dark surfaces (`#141417`), crisp 1px borders, high-contrast monochrome transport controls, and square artwork stage.
- **📊 Real-Time Audio Visualizer**: Animated 16-band spectrum equalizer reflecting live audio output.
- **🔒 100% Offline & Private**: Zero network dependencies, zero tracking, zero login. Operates completely offline on your Mac's hardware.

---

## 🛠️ Building from Source

### Prerequisites
- macOS 13.0 or later
- Swift 6.0+ (Command Line Tools)

### Build Command

Clone the repository and run the build script:

```bash
git clone https://github.com/variable005/san.git
cd san
./build.sh
```

The script compiles `src/main.swift` with `swiftc` and generates two output files in `dist/`:
- `dist/San.app` (Native macOS Application)
- `dist/San.dmg` (Mountable Disk Image Installer)

---

## 📥 Installation

1. Download or build [`San.dmg`](dist/San.dmg).
2. Double-click `San.dmg` to mount the disk image.
3. Drag **San** into your `/Applications` folder.

Or launch directly via terminal:
```bash
open dist/San.app
```

---

## 📁 Repository Structure

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

---

## 📄 License

MIT License © 2026 San
