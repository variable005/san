import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Playlist Exporter & USB/DAP Sync Engine

class PlaylistSyncManager {
    static let shared = PlaylistSyncManager()
    
    func generateM3UContent(tracks: [Track], relativeTo baseDirectoryURL: URL? = nil, customPaths: [String]? = nil) -> String {
        var lines: [String] = ["#EXTM3U"]
        for (index, track) in tracks.enumerated() {
            let duration = Int(track.duration)
            let titleLine = "#EXTINF:\(duration),\(track.artist) - \(track.title)"
            lines.append(titleLine)
            
            if let customPaths = customPaths, index < customPaths.count {
                lines.append(customPaths[index])
            } else if let baseURL = baseDirectoryURL {
                let relativePath = getRelativePath(from: baseURL, to: track.url)
                lines.append(relativePath)
            } else {
                lines.append(track.url.path)
            }
        }
        return lines.joined(separator: "\n")
    }
    
    private func getRelativePath(from baseURL: URL, to targetURL: URL) -> String {
        let baseComponents = baseURL.standardized.pathComponents
        let targetComponents = targetURL.standardized.pathComponents
        
        var commonPrefixCount = 0
        for (base, target) in zip(baseComponents, targetComponents) {
            if base == target {
                commonPrefixCount += 1
            } else {
                break
            }
        }
        
        var relativeComponents: [String] = []
        let parentCount = baseComponents.count - commonPrefixCount
        if parentCount > 0 {
            for _ in 0..<parentCount {
                relativeComponents.append("..")
            }
        }
        
        let remainingComponents = targetComponents.suffix(from: commonPrefixCount)
        relativeComponents.append(contentsOf: remainingComponents)
        
        return relativeComponents.joined(separator: "/")
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
        
        let activeWindow = NSApp.windows.first(where: { $0.isKeyWindow }) ?? NSApp.keyWindow
        
        let completion: (NSApplication.ModalResponse) -> Void = { [weak self] response in
            guard let self = self, response == .OK, let destinationURL = savePanel.url else { return }
            
            // Offload string generation and writing to background queue
            DispatchQueue.global(qos: .userInitiated).async {
                let content = self.generateM3UContent(tracks: tracks, relativeTo: destinationURL.deletingLastPathComponent())
                do {
                    try content.write(to: destinationURL, atomically: true, encoding: .utf8)
                } catch {
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.messageText = "Failed to Export Playlist"
                        alert.informativeText = "Could not save playlist file: \(error.localizedDescription)"
                        alert.alertStyle = .critical
                        alert.addButton(withTitle: "OK")
                        if let window = activeWindow {
                            alert.beginSheetModal(for: window, completionHandler: nil)
                        } else {
                            alert.runModal()
                        }
                    }
                }
            }
        }
        
        if let window = activeWindow {
            savePanel.beginSheetModal(for: window, completionHandler: completion)
        } else {
            savePanel.begin(completionHandler: completion)
        }
    }
}
