import AppKit
import SwiftUI

/// Borderless, non-activating panel that behaves like a menu: opens under the status item,
/// closes on outside click, Escape, or losing key status. It never steals focus from your work.
final class PanelWindow: NSPanel {
    var onEscape: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        onEscape?()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { onEscape?() } else { super.keyDown(with: event) }
    }
}

/// Lets the first click land on a button even though the app isn't active.
final class PanelHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

final class PanelController {
    static let gapBelowMenuBar: CGFloat = 4
    static let screenMargin: CGFloat = 12

    private let window: PanelWindow
    private let layout = PanelLayout()
    private var clickMonitor: Any?
    private var resignObserver: NSObjectProtocol?
    var onClose: (() -> Void)?

    var isVisible: Bool { window.isVisible }

    init(tracker: Tracker) {
        let size = NSSize(width: Metrics.panelWidth, height: Metrics.panelHeight + Metrics.caretHeight)
        window = PanelWindow(contentRect: NSRect(origin: .zero, size: size),
                             styleMask: [.borderless, .nonactivatingPanel],
                             backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .popUpMenu
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.isMovable = false
        window.animationBehavior = .none
        window.acceptsMouseMovedEvents = true
        window.isExcludedFromWindowsMenu = true

        let host = PanelHostingView(rootView: PanelRoot(tracker: tracker, layout: layout))
        host.frame = NSRect(origin: .zero, size: size)
        window.contentView = host

        window.onEscape = { [weak self] in self?.close() }
        resignObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification, object: window, queue: .main
        ) { [weak self] _ in self?.close() }
    }

    func show(relativeTo button: NSStatusBarButton) {
        let size = window.frame.size
        let anchor = anchorRect(for: button)
        let screen = button.window?.screen ?? NSScreen.main ?? NSScreen.screens.first
        let bounds = screen?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        let minX = bounds.minX + Self.screenMargin
        let maxX = bounds.maxX - size.width - Self.screenMargin
        let x = min(max(anchor.midX - size.width / 2, minX), maxX)
        let top = anchor.minY - Self.gapBelowMenuBar
        let frame = NSRect(x: x, y: top - size.height, width: size.width, height: size.height)

        layout.caretX = min(max(anchor.midX - x, 16), size.width - 16)
        if ProcessInfo.processInfo.environment["SPLIT_DEBUG"] != nil {
            NSLog("Split panel: anchor=\(anchor) itemVisible=\(Self.visibleFrame(of: button) != nil) frame=\(frame) screen=\(bounds)")
        }
        window.setFrame(frame, display: true)
        window.makeKeyAndOrderFront(nil)
        window.invalidateShadow()
        installClickMonitor()
    }

    func close() {
        guard window.isVisible else { return }
        window.orderOut(nil)
        removeClickMonitor()
        onClose?()
    }

    /// Screen rect of the status item. While the menu bar is hidden (Mission Control, a
    /// full-screen app) the item's window is parked off-screen, so the rect is only trusted when
    /// it actually lies on a screen; otherwise the panel opens at the top-right of the main screen.
    private func anchorRect(for button: NSStatusBarButton) -> NSRect {
        if let rect = Self.visibleFrame(of: button) { return rect }
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let menuBarHeight = max(screen.frame.maxY - screen.visibleFrame.maxY, 24)
        return NSRect(x: screen.frame.maxX - 100, y: screen.frame.maxY - menuBarHeight, width: 60, height: menuBarHeight)
    }

    /// The status item's screen frame, or nil when macOS isn't actually showing it: parked
    /// off-screen while the menu bar is hidden, or hidden because the menu bar is full (on a
    /// notched Mac the item then sits under the notch or is stacked on top of the clock).
    static func visibleFrame(of button: NSStatusBarButton) -> NSRect? {
        guard let itemWindow = button.window else { return nil }
        let rect = itemWindow.convertToScreen(button.convert(button.bounds, to: nil))
        guard rect.width > 0, let screen = NSScreen.screens.first(where: { $0.frame.intersects(rect) }) else { return nil }
        if #available(macOS 12.0, *), let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea,
           !(left.contains(rect) || right.contains(rect)) {
            return nil
        }
        if isStackedOnAnotherItem(rect) { return nil }
        return rect
    }

    /// True when another process's menu bar item occupies the same spot: that's how macOS parks
    /// items it has no room for. Window bounds are readable without any permission.
    private static func isStackedOnAnotherItem(_ rect: NSRect) -> Bool {
        guard let primary = NSScreen.screens.first else { return false }
        let cgRect = CGRect(x: rect.minX, y: primary.frame.maxY - rect.maxY, width: rect.width, height: rect.height)
        let pid = ProcessInfo.processInfo.processIdentifier
        let statusBarLayer = Int(CGWindowLevelForKey(.statusWindow))
        let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
        return windows.contains { info in
            guard (info[kCGWindowLayer as String] as? Int) == statusBarLayer,
                  (info[kCGWindowOwnerPID as String] as? Int32) != pid,
                  let bounds = info[kCGWindowBounds as String] as? NSDictionary,
                  let other = CGRect(dictionaryRepresentation: bounds) else { return false }
            return other.intersection(cgRect).width > 4
        }
    }

    private func installClickMonitor() {
        removeClickMonitor()
        clickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            self?.close()
        }
    }

    private func removeClickMonitor() {
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
    }
}
