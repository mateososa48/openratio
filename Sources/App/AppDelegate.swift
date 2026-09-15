import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var store: Store!
    private var tracker: Tracker!
    private var statusItem: StatusItemController!
    private var sleepObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        quitIfAlreadyRunning()

        store = Store()
        tracker = Tracker(store: store, source: ActiveContext(), away: IdleMonitor())
        statusItem = StatusItemController(tracker: tracker)
        tracker.start()

        sleepObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.tracker.flush() }

        if !store.data.settings.hasLaunchedBefore {
            store.update { $0.settings.hasLaunchedBefore = true }
            store.save()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.statusItem.openPanel()
                self?.warnIfItemHidden()
            }
        }
    }

    /// On a notched Mac with a full menu bar, macOS silently hides new items. Say so once,
    /// otherwise the app looks like it never launched.
    private func warnIfItemHidden() {
        guard !statusItem.isItemVisible else { return }
        statusItem.closePanel()
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Split is running, but your menu bar is full"
        alert.informativeText = "macOS hides menu bar items it has no room for, and Split's is one of them. Quit an app you don't need in the menu bar (or ⌘-drag items to make room) and Split will appear there as ↑ 67/33.\n\nUntil then, open Split from Spotlight or Launchpad to show this panel."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    /// Double-clicking the app in Finder while it's running opens the panel instead of doing nothing.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        statusItem.openPanel()
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        tracker.flush()
    }

    private func quitIfAlreadyRunning() {
        guard let id = Bundle.main.bundleIdentifier else { return }
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: id)
            .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
        if !others.isEmpty {
            NSLog("Split is already running; exiting this instance.")
            exit(0)
        }
    }
}
