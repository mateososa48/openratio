import AppKit

/// Resolves the frontmost app into a trackable activity. Browsers are split by the host of
/// their active tab (x.com, github.com, …) so a browser isn't one undifferentiated bucket.
final class ActiveContext: ActivitySource {
    private let selfBundleID = Bundle.main.bundleIdentifier ?? ""
    private let urls = BrowserURLProvider()
    private var frontmost: NSRunningApplication?
    private var browserHosts: [String: String] = [:]
    private var lastNonSelf: ResolvedActivity?

    func start() {
        frontmost = NSWorkspace.shared.frontmostApplication
    }

    func refresh() {
        if let app = NSWorkspace.shared.frontmostApplication {
            frontmost = app
        }
        guard let app = frontmost, let id = app.bundleIdentifier, BrowserURLProvider.supports(id) else { return }
        urls.fetchActiveHost(bundleID: id) { [weak self] host in
            self?.browserHosts[id] = host
        }
    }

    var current: ResolvedActivity? {
        guard let app = frontmost else { return lastNonSelf }
        let id = app.bundleIdentifier ?? app.localizedName ?? "unknown"
        // Ignore ourselves and non-regular processes (Spotlight, notification alerts, menu bar
        // agents): the time keeps flowing to the app the user came from.
        if id == selfBundleID || app.activationPolicy != .regular { return lastNonSelf }

        let name = app.localizedName ?? id
        let resolved: ResolvedActivity
        if BrowserURLProvider.supports(id), let host = browserHosts[id] {
            resolved = ResolvedActivity(key: "web:\(host)", name: host)
        } else {
            resolved = ResolvedActivity(key: id, name: name)
        }
        lastNonSelf = resolved
        return resolved
    }
}
