import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let probeURL = URL(string: "https://example.com")!
    private let httpProbe = URL(string: "http://example.com")!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)  // menu bar only, no Dock icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Default Browser")
        }
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    // Rebuild each time the menu opens so the list and checkmark are always current.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let current = NSWorkspace.shared.urlForApplication(toOpen: probeURL)

        for url in browsers() {
            let item = NSMenuItem(title: shortName(for: url), action: #selector(selectBrowser(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = url
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            icon.size = NSSize(width: 16, height: 16)
            item.image = icon
            item.state = (url.standardizedFileURL == current?.standardizedFileURL) ? .on : .off
            menu.addItem(item)
        }
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }

    /// Apps that can open both http and https URLs (filters out most non-browsers).
    private func browsers() -> [URL] {
        let https = Set(NSWorkspace.shared.urlsForApplications(toOpen: probeURL).map { $0.standardizedFileURL })
        let http = Set(NSWorkspace.shared.urlsForApplications(toOpen: httpProbe).map { $0.standardizedFileURL })
        return https.intersection(http).sorted {
            shortName(for: $0).localizedCaseInsensitiveCompare(shortName(for: $1)) == .orderedAscending
        }
    }

    private func shortName(for url: URL) -> String {
        let name = FileManager.default.displayName(atPath: url.path)
        return name.hasSuffix(".app") ? String(name.dropLast(4)) : name
    }

    @objc private func selectBrowser(_ sender: NSMenuItem) {
        guard let appURL = sender.representedObject as? URL else { return }
        // macOS shows its own "Change default browser?" confirmation; that can't be bypassed.
        for scheme in ["http", "https"] {
            NSWorkspace.shared.setDefaultApplication(at: appURL, toOpenURLsWithScheme: scheme) { error in
                if let error = error { NSLog("Failed to set \(scheme) handler: \(error)") }
            }
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
