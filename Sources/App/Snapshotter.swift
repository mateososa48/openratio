import AppKit
import SwiftUI

/// Renders the panel in every state with fixture data, at 2x, to PNG files.
enum Snapshotter {
    static func run(directory: URL) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for (name, tracker) in fixtures() {
            let layout = PanelLayout()
            layout.caretX = 180
            let root = PanelRoot(tracker: tracker, layout: layout)
            let size = CGSize(width: Metrics.panelWidth, height: Metrics.panelHeight + Metrics.caretHeight)
            guard let png = render(root, size: size) else {
                FileHandle.standardError.write("failed to render \(name)\n".data(using: .utf8)!)
                continue
            }
            let url = directory.appendingPathComponent("\(name).png")
            try? png.write(to: url)
            print(url.path)
        }
    }

    static func render<V: View>(_ view: V, size: CGSize, scale: CGFloat = 2) -> Data? {
        let host = NSHostingView(rootView: view)
        host.frame = CGRect(origin: .zero, size: size)
        let window = NSWindow(contentRect: host.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(size.width * scale), pixelsHigh: Int(size.height * scale),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) else { return nil }
        rep.size = size
        host.cacheDisplay(in: host.bounds, to: rep)
        return rep.representation(using: .png, properties: [:])
    }

    // MARK: - Fixtures (mirrors the reference demo's numbers)

    private static func fixtures() -> [(String, Tracker)] {
        var result: [(String, Tracker)] = []

        func make(theme: Theme, configure: (Tracker) -> Void) -> Tracker {
            let dir = FileManager.default.temporaryDirectory
                .appendingPathComponent("openratio-snapshots-\(UUID().uuidString)", isDirectory: true)
            let store = Store(directory: dir)
            store.update { $0.settings.theme = theme }
            let tracker = Tracker(store: store, source: StaticActivitySource(), away: StaticAwayDetector())
            configure(tracker)
            return tracker
        }

        let now = Date()
        func activity(_ key: String, _ name: String, _ seconds: Double, ago: TimeInterval) -> Activity {
            Activity(key: key, name: name, seconds: seconds, lastUsed: now.addingTimeInterval(-ago))
        }
        var today = DayRecord()
        for a in [
            activity("figma", "Figma", 8040, ago: 0),
            activity("youtube", "youtube.com", 2900, ago: 60),
            activity("slack", "Slack", 1810, ago: 120),
            activity("terminal", "Terminal", 2480, ago: 180),
            activity("reddit", "reddit.com", 570, ago: 240),
            activity("obsidian", "Obsidian", 1855, ago: 300),
            activity("hn", "news.ycombinator.com", 1405, ago: 360),
            activity("spotify", "Spotify", 375, ago: 420),
        ] { today.activities[a.key] = a }

        let categories: [String: Category] = [
            "figma": .create, "terminal": .create, "obsidian": .create,
            "youtube": .consume, "slack": .consume, "hn": .consume,
            "past-create": .create, "past-consume": .consume,
        ]

        var past: [String: DayRecord] = [:]
        for (daysAgo, create, consume) in [(1, 71.0, 29.0), (2, 64.0, 36.0), (3, 45.0, 55.0), (4, 58.0, 42.0)] {
            let key = Format.dayKey(now.addingTimeInterval(-Double(daysAgo) * 86_400))
            var record = DayRecord()
            record.activities["past-create"] = Activity(key: "past-create", name: "create", seconds: create * 60, lastUsed: nil)
            record.activities["past-consume"] = Activity(key: "past-consume", name: "consume", seconds: consume * 60, lastUsed: nil)
            past[key] = record
        }

        for theme in [Theme.dark, .light] {
            let prefix = theme == .dark ? "dark" : "light"

            result.append(("\(prefix)-activity", make(theme: theme) {
                $0.applyState(today: today, categories: categories, currentKey: "figma", pastDays: past)
            }))
            result.append(("\(prefix)-away", make(theme: theme) {
                $0.applyState(today: today, categories: categories, currentKey: "figma", isAway: true, pastDays: past)
            }))
            result.append(("\(prefix)-paused", make(theme: theme) {
                $0.applyState(today: today, categories: categories, currentKey: "figma", isPaused: true, pastDays: past)
            }))
            result.append(("\(prefix)-pending", make(theme: theme) {
                $0.applyState(today: today, categories: categories, currentKey: "figma", pastDays: past)
                $0.togglePendingOnly()
            }))
            result.append(("\(prefix)-history", make(theme: theme) {
                $0.applyState(today: today, categories: categories, currentKey: "figma", pastDays: past)
                $0.toggleHistory()
            }))
            result.append(("\(prefix)-empty", make(theme: theme) {
                var fresh = DayRecord()
                fresh.activities["figma"] = Activity(key: "figma", name: "Figma", seconds: 0, lastUsed: now)
                $0.applyState(today: fresh, categories: ["figma": .create], currentKey: "figma", isAway: true)
            }))
        }
        return result
    }
}
