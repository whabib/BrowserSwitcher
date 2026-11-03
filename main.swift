import AppKit
import ServiceManagement

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
            // Embed the icon in the title itself rather than using NSMenuItem.image,
            // which some macOS versions don't draw for status item menus.
            let attachment = NSTextAttachment()
            attachment.image = menuIcon(for: url)
            attachment.bounds = CGRect(x: 0, y: -3, width: 16, height: 16)
            let title = NSMutableAttributedString(attachment: attachment)
            title.append(NSAttributedString(string: "  " + shortName(for: url)))
            title.addAttribute(.font, value: NSFont.menuFont(ofSize: 0), range: NSRange(location: 0, length: title.length))
            item.attributedTitle = title
            item.state = (url.standardizedFileURL == current?.standardizedFileURL) ? .on : .off
            menu.addItem(item)
        }
        menu.addItem(.separator())

        let login = NSMenuItem(title: "Start at Login", action: #selector(toggleLogin(_:)), keyEquivalent: "")
        login.target = self
        login.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
        menu.addItem(login)

        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }

    /// Renders the app icon into a fresh 16x16 image so the menu always gets a correctly sized bitmap.
    private func menuIcon(for url: URL) -> NSImage {
        let source = NSWorkspace.shared.icon(forFile: url.path)
        let size = NSSize(width: 16, height: 16)
        let image = NSImage(size: size, flipped: false) { rect in
            source.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
            return true
        }
        image.isTemplate = false
        return image
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

    @objc private func toggleLogin(_ sender: NSMenuItem) {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            NSLog("Login item change failed: \(error)")
            let alert = NSAlert()
            alert.messageText = "Couldn't change the login item"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
        if service.status == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
    }

    @objc private func selectBrowser(_ sender: NSMenuItem) {
        guard let appURL = sender.representedObject as? URL else { return }
        // Set http first and wait for it. macOS may switch https along with it; only
        // if https is still on the old browser do we set it too (a second system prompt).
        NSWorkspace.shared.setDefaultApplication(at: appURL, toOpenURLsWithScheme: "http") { [weak self] error in
            if let error = error {
                NSLog("Failed to set http handler: \(error)")
                return  // cancelled or failed: don't ask a second time
            }
            DispatchQueue.main.async { self?.setHTTPSIfNeeded(appURL) }
        }
    }

    private func setHTTPSIfNeeded(_ appURL: URL) {
        let current = NSWorkspace.shared.urlForApplication(toOpen: probeURL)
        guard current?.standardizedFileURL != appURL.standardizedFileURL else { return }
        NSWorkspace.shared.setDefaultApplication(at: appURL, toOpenURLsWithScheme: "https") { error in
            if let error = error { NSLog("Failed to set https handler: \(error)") }
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
