import Foundation

/// Asks a browser for its active tab's URL over Apple Events (the first call per browser triggers
/// macOS's one-time "OpenRatio wants to control Safari" consent). Firefox has no scripting interface,
/// so it is tracked as an app. Nothing is stored except the host name.
final class BrowserURLProvider {
    enum Kind { case safari, chromium }

    static let known: [String: Kind] = [
        "com.apple.Safari": .safari,
        "com.apple.SafariTechnologyPreview": .safari,
        "com.google.Chrome": .chromium,
        "com.google.Chrome.beta": .chromium,
        "com.google.Chrome.dev": .chromium,
        "com.google.Chrome.canary": .chromium,
        "org.chromium.Chromium": .chromium,
        "com.brave.Browser": .chromium,
        "com.brave.Browser.beta": .chromium,
        "com.brave.Browser.nightly": .chromium,
        "com.microsoft.edgemac": .chromium,
        "com.microsoft.edgemac.Beta": .chromium,
        "com.microsoft.edgemac.Dev": .chromium,
        "com.microsoft.edgemac.Canary": .chromium,
        "com.vivaldi.Vivaldi": .chromium,
        "com.operasoftware.Opera": .chromium,
        "com.operasoftware.OperaGX": .chromium,
        "company.thebrowser.Browser": .chromium, // Arc
        "company.thebrowser.dia": .chromium,     // Dia
    ]

    static func supports(_ bundleID: String) -> Bool { known[bundleID] != nil }

    private enum Outcome { case url(String?), denied, failed }

    private let queue = DispatchQueue(label: "com.openratio.app.browser-url", qos: .utility)
    private var scripts: [String: NSAppleScript] = [:]   // touched only on `queue`
    private var inFlight = false                          // touched only on main
    private var retryAfter: [String: Date] = [:]          // touched only on main

    /// Completion runs on the main thread with the active tab's host, or nil when the front tab
    /// isn't a web page (new tab, settings, file://) or the request failed.
    func fetchActiveHost(bundleID: String, completion: @escaping (String?) -> Void) {
        guard !inFlight else { return }
        if let until = retryAfter[bundleID], until > Date() { return }
        inFlight = true
        queue.async {
            let outcome = self.run(bundleID)
            DispatchQueue.main.async {
                self.inFlight = false
                switch outcome {
                case .url(let string):
                    completion(Self.host(from: string))
                case .denied:
                    // User said no (or hasn't answered yet). Back off and try again later.
                    self.retryAfter[bundleID] = Date().addingTimeInterval(60)
                    completion(nil)
                case .failed:
                    self.retryAfter[bundleID] = Date().addingTimeInterval(5)
                    completion(nil)
                }
            }
        }
    }

    private func run(_ bundleID: String) -> Outcome {
        let script: NSAppleScript
        if let cached = scripts[bundleID] {
            script = cached
        } else {
            guard let kind = Self.known[bundleID], let made = NSAppleScript(source: Self.source(for: bundleID, kind: kind)) else {
                return .failed
            }
            scripts[bundleID] = made
            script = made
        }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if let error {
            let code = error[NSAppleScript.errorNumber] as? Int ?? 0
            // -1743: not permitted; -1744: would require user consent (can't prompt right now).
            return (code == -1743 || code == -1744) ? .denied : .failed
        }
        return .url(result.stringValue)
    }

    private static func source(for bundleID: String, kind: Kind) -> String {
        let tab = kind == .safari ? "current tab" : "active tab"
        return """
        tell application id "\(bundleID)"
            if (count of windows) is 0 then return ""
            return URL of \(tab) of front window
        end tell
        """
    }

    /// "https://www.x.com/home" → "x.com"; anything that isn't http(s) → nil.
    static func host(from urlString: String?) -> String? {
        guard let string = urlString?.trimmingCharacters(in: .whitespacesAndNewlines), !string.isEmpty,
              let url = URL(string: string),
              let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
              var host = url.host?.lowercased(), !host.isEmpty else { return nil }
        if host.hasPrefix("www.") { host.removeFirst(4) }
        return host.isEmpty ? nil : host
    }
}
