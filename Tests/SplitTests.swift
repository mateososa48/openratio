import XCTest
@testable import Split

final class RatioTests: XCTestCase {
    func testPercentagesMatchReferenceRounding() {
        let s = RatioSummary(createSeconds: 267, consumeSeconds: 133)
        XCTAssertEqual(s.createPercent, 67)
        XCTAssertEqual(s.consumePercent, 33)
        XCTAssertEqual(s.createPercentText, "66.75%")
        XCTAssertEqual(s.consumePercentText, "33.25%")
        XCTAssertEqual(s.ratioText, "67/33")
    }

    func testComplementAlwaysSumsToOneHundred() {
        let s = RatioSummary(createSeconds: 1, consumeSeconds: 2)
        XCTAssertEqual(s.createPercentText, "33.33%")
        XCTAssertEqual(s.consumePercentText, "66.67%")
    }

    func testEmpty() {
        let s = RatioSummary(createSeconds: 0, consumeSeconds: 0)
        XCTAssertFalse(s.hasData)
        XCTAssertEqual(s.ratioText, "—/—")
        XCTAssertEqual(s.createPercentText, "—")
    }
}

final class FormatTests: XCTestCase {
    func testDuration() {
        XCTAssertEqual(Format.duration(0), "0:00")
        XCTAssertEqual(Format.duration(54.9), "0:54")
        XCTAssertEqual(Format.duration(180), "3:00")
        XCTAssertEqual(Format.duration(3661), "1:01:01")
        XCTAssertEqual(Format.duration(36_000), "10:00:00")
    }

    func testDaysText() {
        XCTAssertEqual(Format.daysText(1), "1 DAY")
        XCTAssertEqual(Format.daysText(5), "5 DAYS")
    }

    func testDayLabel() {
        XCTAssertEqual(Format.dayLabel(key: "2026-09-15", todayKey: "2026-09-15"), "TODAY")
        XCTAssertEqual(Format.dayLabel(key: "2026-09-14", todayKey: "2026-09-15"), "SEP 14")
    }
}

final class BrowserHostTests: XCTestCase {
    func testHostExtraction() {
        XCTAssertEqual(BrowserURLProvider.host(from: "https://www.x.com/home"), "x.com")
        XCTAssertEqual(BrowserURLProvider.host(from: "http://GitHub.com/a/b"), "github.com")
        XCTAssertNil(BrowserURLProvider.host(from: "chrome://newtab/"))
        XCTAssertNil(BrowserURLProvider.host(from: "file:///Users/me/doc.html"))
        XCTAssertNil(BrowserURLProvider.host(from: ""))
        XCTAssertNil(BrowserURLProvider.host(from: nil))
    }
}

final class TrackerTests: XCTestCase {
    private var dir: URL!
    private var store: Store!
    private var source: StaticActivitySource!
    private var away: StaticAwayDetector!
    private var clock: Date!

    override func setUp() {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent("split-tests-\(UUID().uuidString)")
        store = Store(directory: dir)
        source = StaticActivitySource(ResolvedActivity(key: "cursor", name: "Cursor"))
        away = StaticAwayDetector()
        clock = Date(timeIntervalSince1970: 1_800_000_000) // a fixed instant; day key derived from local calendar
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: dir)
    }

    private func makeTracker() -> Tracker {
        Tracker(store: store, source: source, away: away) { [unowned self] in self.clock }
    }

    private func advance(_ tracker: Tracker, seconds: Int) {
        for _ in 0..<seconds {
            clock = clock.addingTimeInterval(1)
            tracker.tick()
        }
    }

    func testAccumulatesOnlyWhileLive() {
        let tracker = makeTracker()
        advance(tracker, seconds: 5)
        XCTAssertEqual(tracker.today.activities["cursor"]?.seconds, 5)
        XCTAssertTrue(tracker.isLive)

        away.isAway = true
        advance(tracker, seconds: 5)
        XCTAssertEqual(tracker.today.activities["cursor"]?.seconds, 5)
        XCTAssertTrue(tracker.isAway)
        XCTAssertEqual(tracker.trackingLabel, "AWAY")

        away.isAway = false
        tracker.togglePause()
        advance(tracker, seconds: 5)
        XCTAssertEqual(tracker.today.activities["cursor"]?.seconds, 5)
        XCTAssertEqual(tracker.trackingLabel, "PAUSED")
        XCTAssertEqual(tracker.menuBarState.tone, .neutral)
        XCTAssertTrue(tracker.menuBarState.title.hasPrefix("Ⅱ"))
    }

    func testLongGapsAreCapped() {
        let tracker = makeTracker()
        clock = clock.addingTimeInterval(3600)
        tracker.tick()
        XCTAssertEqual(tracker.today.activities["cursor"]?.seconds, Tracker.maxElapsedPerTick)
    }

    func testMenuBarReflectsCurrentCategory() {
        let tracker = makeTracker()
        advance(tracker, seconds: 2)
        XCTAssertEqual(tracker.menuBarState, MenuBarState(title: "? —/—", tone: .unclassified))
        tracker.classify("cursor", as: .create)
        XCTAssertEqual(tracker.menuBarState, MenuBarState(title: "↑ 100/0", tone: .create))
    }

    func testRowsAreMostRecentFirstAndCurrentShowsAtZero() {
        let tracker = makeTracker()
        advance(tracker, seconds: 10)
        source.current = ResolvedActivity(key: "web:x.com", name: "x.com")
        tracker.tick() // switch: x.com appears immediately, before it has any time
        XCTAssertEqual(tracker.rows.map(\.key), ["web:x.com", "cursor"])
        XCTAssertTrue(tracker.rows[0].isCurrent)
        XCTAssertEqual(tracker.pendingCount, 2)
    }

    func testPendingFilterClearsWhenEverythingIsClassified() {
        let tracker = makeTracker()
        advance(tracker, seconds: 3)
        tracker.togglePendingOnly()
        XCTAssertEqual(tracker.trackingLabel, "TO CATEGORIZE")
        tracker.classify("cursor", as: .create)
        XCTAssertFalse(tracker.pendingOnly)
        XCTAssertEqual(tracker.pendingCount, 0)
        XCTAssertEqual(store.data.categories["cursor"], .create)
    }

    func testResetAndUndo() {
        let tracker = makeTracker()
        tracker.classify("cursor", as: .create)
        advance(tracker, seconds: 30)
        XCTAssertEqual(tracker.totalSeconds, 30)

        tracker.reset()
        XCTAssertTrue(tracker.canUndo)
        XCTAssertEqual(tracker.totalSeconds, 0)
        XCTAssertEqual(tracker.rows.map(\.key), ["cursor"]) // current row stays visible at 0:00

        tracker.undo()
        XCTAssertFalse(tracker.canUndo)
        XCTAssertEqual(tracker.totalSeconds, 30)
    }

    func testDayRolloverMovesTodayIntoHistory() {
        let tracker = makeTracker()
        tracker.classify("cursor", as: .create)
        advance(tracker, seconds: 20)
        let firstKey = tracker.todayKey

        clock = clock.addingTimeInterval(86_400)
        tracker.tick()
        XCTAssertNotEqual(tracker.todayKey, firstKey)
        XCTAssertEqual(store.data.days[firstKey]?.totalSeconds, 20)
        XCTAssertEqual(tracker.history.count, 2)
        XCTAssertEqual(tracker.history[0].label, "TODAY")
        XCTAssertEqual(tracker.history[1].summary.ratioText, "100/0")
    }

    func testPersistsAndReloads() {
        let tracker = makeTracker()
        tracker.classify("cursor", as: .create)
        advance(tracker, seconds: 12)
        tracker.flush()

        let reloaded = Tracker(store: Store(directory: dir), source: source, away: away) { [unowned self] in self.clock }
        XCTAssertEqual(reloaded.today.activities["cursor"]?.seconds, 12)
        XCTAssertEqual(reloaded.categories["cursor"], .create)
    }

    func testCorruptFileIsMovedAsideNotOverwritten() throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try "not json".write(to: dir.appendingPathComponent("data.json"), atomically: true, encoding: .utf8)
        let fresh = Store(directory: dir)
        XCTAssertTrue(fresh.data.days.isEmpty)
        let files = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        XCTAssertTrue(files.contains { $0.hasPrefix("data.corrupt-") })
    }
}
