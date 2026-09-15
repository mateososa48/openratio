import AppKit

/// The menu bar item: "↑ 67/33" while creating, "↓ 67/33" while consuming, "? 67/33" for an
/// unclassified app, "Ⅱ —/—" when paused or away. Left click toggles the panel, right click
/// opens the utility menu.
final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let tracker: Tracker
    private let panel: PanelController
    private var lastState: MenuBarState?
    private var lastToggle = Date.distantPast
    private let font = NSFont.monospacedSystemFont(ofSize: Metrics.fontSize, weight: .regular)

    init(tracker: Tracker) {
        self.tracker = tracker
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        panel = PanelController(tracker: tracker)
        super.init()

        statusItem.autosaveName = "OpenRatio"
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(handleClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.setAccessibilityLabel("OpenRatio")
        }
        tracker.onChange = { [weak self] in self?.refresh() }
        panel.onClose = { [weak self] in self?.statusItem.button?.highlight(false) }
        refresh()
    }

    /// False when the menu bar has no room and macOS is hiding the item behind the notch.
    var isItemVisible: Bool {
        guard let button = statusItem.button else { return false }
        return PanelController.visibleFrame(of: button) != nil
    }

    func openPanel() {
        guard !panel.isVisible, let button = statusItem.button else { return }
        panel.show(relativeTo: button)
        button.highlight(true)
    }

    func closePanel() {
        panel.close()
    }

    private func refresh() {
        let state = tracker.menuBarState
        guard state != lastState, let button = statusItem.button else { return }
        lastState = state

        var attributes: [NSAttributedString.Key: Any] = [.font: font]
        switch state.tone {
        case .create: attributes[.foregroundColor] = Palette.nsGreen
        case .consume: attributes[.foregroundColor] = Palette.nsRed
        case .unclassified: attributes[.foregroundColor] = Palette.nsOrange
        case .neutral: break
        }
        button.attributedTitle = NSAttributedString(string: state.title, attributes: attributes)
        button.setAccessibilityValue(state.title)
    }

    @objc private func handleClick() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showMenu()
            return
        }
        // A resign-key close and the button's own action can both fire on one click.
        guard Date().timeIntervalSince(lastToggle) > 0.2 else { return }
        lastToggle = Date()
        if panel.isVisible { closePanel() } else { openPanel() }
    }

    private func showMenu() {
        closePanel()
        let menu = NSMenu()
        menu.delegate = self

        let launch = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launch.target = self
        launch.state = LaunchAtLogin.isEnabled ? .on : .off
        menu.addItem(launch)

        let reveal = NSMenuItem(title: "Show Data File in Finder", action: #selector(revealData), keyEquivalent: "")
        reveal.target = self
        menu.addItem(reveal)

        menu.addItem(.separator())

        let about = NSMenuItem(title: "About OpenRatio", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)

        let quit = NSMenuItem(title: "Quit OpenRatio", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        guard let button = statusItem.button else { return }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 6), in: button)
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            try LaunchAtLogin.setEnabled(!LaunchAtLogin.isEnabled)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Couldn't change Launch at Login"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    @objc private func revealData() {
        NSWorkspace.shared.activateFileViewerSelecting([Store.defaultDirectory().appendingPathComponent("data.json")])
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
