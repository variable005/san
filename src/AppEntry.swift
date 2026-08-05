import SwiftUI
import AppKit

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
