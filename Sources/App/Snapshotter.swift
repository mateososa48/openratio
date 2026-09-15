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
                .appendingPathComponent("split-snapshots-\(UUID().uuidString)", isDirectory: true)
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
            activity("stripe", "Stripe", 54, ago: 0),
            activity("cursor", "Cursor", 180, ago: 60),
            activity("web:x.com", "x.com", 90, ago: 120),
            activity("youtube", "YouTube", 76, ago: 180),
            activity("messages", "Messages", 47, ago: 240),
            activity("terminal", "Terminal", 41, ago: 300),
            activity("essay", "Essay", 24, ago: 360),
            activity("web:github.com", "github.com", 18, ago: 420),
            activity("notes", "Notes", 12, ago: 480),
        ] { today.activities[a.key] = a }

        let categories: [String: Category] = [
            "cursor": .create, "web:x.com": .consume, "messages": .consume, "terminal": .create,
            "essay": .create, "web:github.com": .create, "notes": .create, "past-create": .create, "past-consume": .consume,
        ]

        var past: [String: DayRecord] = [:]
        for (daysAgo, create, consume) in [(1, 67.0, 33.0), (2, 58.0, 42.0), (3, 49.0, 51.0), (4, 42.0, 58.0)] {
            let key = Format.dayKey(now.addingTimeInterval(-Double(daysAgo) * 86_400))
            var record = DayRecord()
            record.activities["past-create"] = Activity(key: "past-create", name: "create", seconds: create * 60, lastUsed: nil)
            record.activities["past-consume"] = Activity(key: "past-consume", name: "consume", seconds: consume * 60, lastUsed: nil)
            past[key] = record
        }

        for theme in [Theme.dark, .light] {
            let prefix = theme == .dark ? "dark" : "light"

            result.append(("\(prefix)-activity", make(theme: theme) {
                $0.applyState(today: today, categories: categories, currentKey: "stripe", pastDays: past)
            }))
            result.append(("\(prefix)-away", make(theme: theme) {
                $0.applyState(today: today, categories: categories, currentKey: "stripe", isAway: true, pastDays: past)
            }))
            result.append(("\(prefix)-paused", make(theme: theme) {
                $0.applyState(today: today, categories: categories, currentKey: "stripe", isPaused: true, pastDays: past)
            }))
            result.append(("\(prefix)-pending", make(theme: theme) {
                $0.applyState(today: today, categories: categories, currentKey: "stripe", pastDays: past)
                $0.togglePendingOnly()
            }))
            result.append(("\(prefix)-history", make(theme: theme) {
                $0.applyState(today: today, categories: categories, currentKey: "stripe", pastDays: past)
                $0.toggleHistory()
            }))
            result.append(("\(prefix)-empty", make(theme: theme) {
                var fresh = DayRecord()
                fresh.activities["cursor"] = Activity(key: "cursor", name: "Cursor", seconds: 0, lastUsed: now)
                $0.applyState(today: fresh, categories: ["cursor": .create], currentKey: "cursor", isAway: true)
            }))
        }
        return result
    }
}
