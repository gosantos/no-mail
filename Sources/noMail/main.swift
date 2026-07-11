import Cocoa

// MARK: - Configuration keys (read/writable via `defaults` on the app's domain)

private enum Keys {
    static let enabled = "enabled"           // Bool  – is blocking active
    static let hideIcon = "hideIcon"         // Bool  – hide the menu bar icon
    static let replacement = "replacement"   // String – app path or URL to open instead of Mail
    static let blockedBundleId = "blockedBundleId" // String – override the blocked app
}

private let defaultBlockedBundleId = "com.apple.mail"

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let defaults = UserDefaults.standard

    /// Bundle id we prevent from launching. Defaults to Apple Mail, override-able via defaults.
    private var blockedBundleId: String {
        let value = defaults.string(forKey: Keys.blockedBundleId)
        return (value?.isEmpty == false) ? value! : defaultBlockedBundleId
    }

    /// Blocking is on by default (first launch has no stored value).
    private var isEnabled: Bool {
        get { defaults.object(forKey: Keys.enabled) == nil ? true : defaults.bool(forKey: Keys.enabled) }
        set {
            defaults.set(newValue, forKey: Keys.enabled)
            updateIcon()
            if newValue { terminateBlockedApps() }
        }
    }

    // MARK: Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        if !defaults.bool(forKey: Keys.hideIcon) {
            setupStatusItem()
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(applicationLaunched(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )

        // Handle the case where Mail is already running when we start up.
        if isEnabled { terminateBlockedApps() }
    }

    // MARK: Blocking

    @objc private func applicationLaunched(_ notification: Notification) {
        guard isEnabled else { return }
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        guard app.bundleIdentifier == blockedBundleId else { return }
        terminate(app)
        openReplacementIfNeeded()
    }

    private func terminateBlockedApps() {
        let id = blockedBundleId
        for app in NSWorkspace.shared.runningApplications where app.bundleIdentifier == id {
            terminate(app)
        }
    }

    private func terminate(_ app: NSRunningApplication) {
        if !app.terminate() {
            app.forceTerminate()
        }
    }

    private func openReplacementIfNeeded() {
        guard let replacement = defaults.string(forKey: Keys.replacement),
              !replacement.isEmpty else { return }

        // A path -> launch that app. Anything with a URL scheme -> open the URL.
        if replacement.hasPrefix("/") {
            let url = URL(fileURLWithPath: replacement)
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        } else if let url = URL(string: replacement), url.scheme != nil {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: Status bar item

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem = item
        updateIcon()
    }

    private func updateIcon() {
        guard let button = statusItem?.button else { return }
        let symbol = isEnabled ? "envelope.slash" : "envelope"
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "noMail")
        image?.isTemplate = true
        button.image = image
        button.toolTip = isEnabled ? "noMail: enabled (Mail is blocked)" : "noMail: disabled"
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        let isRightClick = event?.type == .rightMouseUp
        let isControlClick = event?.modifierFlags.contains(.control) == true

        if isRightClick || isControlClick {
            showContextMenu()
        } else {
            isEnabled.toggle()
        }
    }

    private func showContextMenu() {
        guard let item = statusItem else { return }
        let menu = NSMenu()

        let toggleTitle = isEnabled ? "Disable noMail" : "Enable noMail"
        menu.addItem(withTitle: toggleTitle, action: #selector(toggleFromMenu), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Hide Icon", action: #selector(hideIcon), keyEquivalent: "")
        menu.addItem(withTitle: "Quit noMail", action: #selector(quit), keyEquivalent: "q")
        for menuItem in menu.items { menuItem.target = self }

        // Attach the menu just long enough to pop it, then detach so left-click
        // keeps toggling instead of opening the menu.
        item.menu = menu
        item.button?.performClick(nil)
        item.menu = nil
    }

    @objc private func toggleFromMenu() { isEnabled.toggle() }

    @objc private func hideIcon() {
        defaults.set(true, forKey: Keys.hideIcon)
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        statusItem = nil
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

// MARK: - Entry point

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // no Dock icon, agent-style app
app.run()
