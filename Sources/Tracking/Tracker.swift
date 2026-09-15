import Foundation
import Combine

struct ResolvedActivity: Equatable {
    let key: String
    let name: String
}

/// Where "what is the user doing right now" comes from. Faked in tests and snapshots.
protocol ActivitySource: AnyObject {
    func start()
    func refresh()
    var current: ResolvedActivity? { get }
}

/// Idle / locked / asleep detection. Faked in tests and snapshots.
protocol AwayDetector: AnyObject {
    func start()
    var isAway: Bool { get }
}

enum MenuBarTone: Equatable {
    case neutral, create, consume, unclassified
}

struct MenuBarState: Equatable {
    let title: String
    let tone: MenuBarTone
}

struct ActivityRow: Identifiable, Equatable {
    let key: String
    let name: String
    let seconds: Double
    let category: Category?
    let isCurrent: Bool
    var id: String { key }
}

struct HistoryDay: Identifiable, Equatable {
    let key: String
    let label: String
    let summary: RatioSummary
    var id: String { key }
}

/// The engine. Ticks once a second, attributes elapsed time to the active app or site,
/// and exposes everything the panel and the menu bar render.
final class Tracker: ObservableObject {
    static let tickInterval: TimeInterval = 1
    /// Guards against a sleeping Mac dumping a whole night onto one app.
    static let maxElapsedPerTick: TimeInterval = 2
    static let undoWindow: TimeInterval = 8
    static let historyRetentionDays = 365

    @Published private(set) var today = DayRecord()
    @Published private(set) var categories: [String: Category] = [:]
    @Published private(set) var currentKey: String?
    @Published private(set) var isPaused = false
    @Published private(set) var isAway = false
    @Published private(set) var pendingOnly = false
    @Published private(set) var showHistory = false
    @Published private(set) var theme: Theme = .dark
    @Published private(set) var canUndo = false

    /// Called after every tick and every user action; the status item uses it to refresh its title.
    var onChange: (() -> Void)?

    private(set) var todayKey: String
    private let store: Store
    private let source: ActivitySource
    private let away: AwayDetector
    private let now: () -> Date
    private var timer: Timer?
    private var lastTick: Date
    private var undoSnapshot: DayRecord?
    private var undoTimer: Timer?
    private var ticksSinceSave = 0

    init(store: Store, source: ActivitySource, away: AwayDetector, now: @escaping () -> Date = Date.init) {
        self.store = store
        self.source = source
        self.away = away
        self.now = now
        let start = now()
        lastTick = start
        todayKey = Format.dayKey(start)
        today = store.data.days[todayKey] ?? DayRecord()
        categories = store.data.categories
        theme = store.data.settings.theme
    }

    // MARK: - Lifecycle

    func start() {
        source.start()
        away.start()
        let t = Timer(timeInterval: Self.tickInterval, repeats: true) { [weak self] _ in self?.tick() }
        t.tolerance = 0.1
        RunLoop.main.add(t, forMode: .common)
        timer = t
        tick()
    }

    /// Persist everything now (quit, sleep).
    func flush() {
        persistToday()
        store.save()
    }

    /// One heartbeat. Public so tests can drive time deterministically.
    func tick() {
        let time = now()
        let elapsed = min(max(time.timeIntervalSince(lastTick), 0), Self.maxElapsedPerTick)
        lastTick = time

        rollOverIfNeeded(at: time)
        source.refresh()
        isAway = away.isAway

        if let resolved = source.current {
            if resolved.key != currentKey {
                currentKey = resolved.key
                touch(resolved, at: time)
            }
            if isLive {
                var activity = today.activities[resolved.key]
                    ?? Activity(key: resolved.key, name: resolved.name, seconds: 0, lastUsed: time)
                activity.seconds += elapsed
                activity.lastUsed = time
                activity.name = resolved.name
                today.activities[resolved.key] = activity
            }
        }

        ticksSinceSave += 1
        if ticksSinceSave >= 10 {
            persistToday()
            store.saveIfNeeded()
            ticksSinceSave = 0
        }
        onChange?()
    }

    // MARK: - Derived state

    var isLive: Bool { !isPaused && !isAway && currentKey != nil }

    var currentCategory: Category? { currentKey.flatMap { categories[$0] } }

    var summary: RatioSummary {
        RatioSummary(
            createSeconds: today.seconds(for: .create, categories: categories),
            consumeSeconds: today.seconds(for: .consume, categories: categories)
        )
    }

    var totalSeconds: Double { today.totalSeconds }

    /// Rows for the activity list: the current app on top, then most recently used first.
    var rows: [ActivityRow] {
        today.activities.values
            .filter { $0.seconds > 0 || $0.key == currentKey }
            .filter { !pendingOnly || categories[$0.key] == nil }
            .sorted { a, b in
                if (a.key == currentKey) != (b.key == currentKey) { return a.key == currentKey }
                let la = a.lastUsed ?? .distantPast
                let lb = b.lastUsed ?? .distantPast
                if la != lb { return la > lb }
                if a.seconds != b.seconds { return a.seconds > b.seconds }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
            .map {
                ActivityRow(key: $0.key, name: $0.name, seconds: $0.seconds,
                            category: categories[$0.key], isCurrent: $0.key == currentKey)
            }
    }

    var pendingCount: Int {
        today.activities.values.filter {
            ($0.seconds > 0 || $0.key == currentKey) && categories[$0.key] == nil
        }.count
    }

    var trackingLabel: String {
        if showHistory { return "HISTORY" }
        if pendingOnly { return "TO CATEGORIZE" }
        if isPaused { return "PAUSED" }
        if isAway { return "AWAY" }
        return "TRACKING"
    }

    var menuBarState: MenuBarState {
        let glyph: String
        let tone: MenuBarTone
        if isLive {
            switch currentCategory {
            case .create: glyph = "↑"; tone = .create
            case .consume: glyph = "↓"; tone = .consume
            case nil: glyph = "?"; tone = .unclassified
            }
        } else {
            glyph = "Ⅱ"
            tone = .neutral
        }
        return MenuBarState(title: "\(glyph) \(summary.ratioText)", tone: tone)
    }

    /// Today first, then every past day that has tracked time, newest first.
    var history: [HistoryDay] {
        var days = store.data.days
        days[todayKey] = today
        return days.keys.sorted(by: >).compactMap { key in
            guard let record = days[key], key == todayKey || record.totalSeconds > 0 else { return nil }
            return HistoryDay(
                key: key,
                label: Format.dayLabel(key: key, todayKey: todayKey),
                summary: RatioSummary(
                    createSeconds: record.seconds(for: .create, categories: categories),
                    consumeSeconds: record.seconds(for: .consume, categories: categories)
                )
            )
        }
    }

    // MARK: - Actions

    func classify(_ key: String, as category: Category) {
        categories[key] = category
        store.update { $0.categories[key] = category }
        if pendingCount == 0 { pendingOnly = false }
        store.save()
        onChange?()
    }

    func togglePause() {
        isPaused.toggle()
        onChange?()
    }

    func togglePendingOnly() {
        pendingOnly.toggle()
    }

    func toggleHistory() {
        showHistory.toggle()
    }

    func toggleTheme() {
        theme = theme == .dark ? .light : .dark
        store.update { $0.settings.theme = theme }
        store.save()
    }

    /// Clears today. Undo is offered for `undoWindow` seconds.
    func reset() {
        undoSnapshot = today
        var fresh = DayRecord()
        if let key = currentKey, let previous = today.activities[key] {
            fresh.activities[key] = Activity(key: key, name: previous.name, seconds: 0, lastUsed: now())
        }
        today = fresh
        canUndo = true
        undoTimer?.invalidate()
        undoTimer = Timer.scheduledTimer(withTimeInterval: Self.undoWindow, repeats: false) { [weak self] _ in
            self?.expireUndo()
        }
        persistToday()
        store.save()
        onChange?()
    }

    func undo() {
        guard let snapshot = undoSnapshot else { return }
        today = snapshot
        expireUndo()
        persistToday()
        store.save()
        onChange?()
    }

    func expireUndo() {
        undoSnapshot = nil
        canUndo = false
        undoTimer?.invalidate()
        undoTimer = nil
    }

    /// Load a synthetic state. Used by `--snapshot` rendering and tests; never by the running app.
    func applyState(today: DayRecord, categories: [String: Category], currentKey: String?,
                    isAway: Bool = false, isPaused: Bool = false, pastDays: [String: DayRecord] = [:]) {
        self.today = today
        self.categories = categories
        self.currentKey = currentKey
        self.isAway = isAway
        self.isPaused = isPaused
        store.update { data in
            data.categories = categories
            for (key, record) in pastDays { data.days[key] = record }
        }
    }

    // MARK: - Internals

    private func touch(_ resolved: ResolvedActivity, at time: Date) {
        var activity = today.activities[resolved.key]
            ?? Activity(key: resolved.key, name: resolved.name, seconds: 0, lastUsed: nil)
        activity.lastUsed = time
        activity.name = resolved.name
        today.activities[resolved.key] = activity
    }

    private func persistToday() {
        store.update { $0.days[todayKey] = today }
    }

    private func rollOverIfNeeded(at time: Date) {
        let key = Format.dayKey(time)
        guard key != todayKey else { return }
        store.update { data in
            data.days[todayKey] = today
            let cutoff = Format.dayKey(time.addingTimeInterval(-Double(Self.historyRetentionDays) * 86_400))
            data.days = data.days.filter { $0.key >= cutoff }
        }
        todayKey = key
        today = DayRecord()
        expireUndo()
        if let resolved = source.current {
            currentKey = resolved.key
            touch(resolved, at: time)
        }
        store.save()
    }
}
