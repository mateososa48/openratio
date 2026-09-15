import AppKit
import CoreGraphics

/// Away = no keyboard/mouse input for a minute, or the screen is locked / asleep / saving.
/// None of this needs a permission prompt.
final class IdleMonitor: AwayDetector {
    static let idleThreshold: TimeInterval = 60

    private var isLocked = false
    private var isAsleep = false
    private var isScreenSaving = false
    private var observers: [NSObjectProtocol] = []

    func start() {
        let distributed = DistributedNotificationCenter.default()
        let workspace = NSWorkspace.shared.notificationCenter

        func on(_ center: NotificationCenter, _ name: Notification.Name, _ handler: @escaping () -> Void) {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { _ in handler() })
        }

        on(distributed, .init("com.apple.screenIsLocked")) { [weak self] in self?.isLocked = true }
        on(distributed, .init("com.apple.screenIsUnlocked")) { [weak self] in self?.isLocked = false }
        on(distributed, .init("com.apple.screensaver.didstart")) { [weak self] in self?.isScreenSaving = true }
        on(distributed, .init("com.apple.screensaver.didstop")) { [weak self] in self?.isScreenSaving = false }

        on(workspace, NSWorkspace.willSleepNotification) { [weak self] in self?.isAsleep = true }
        on(workspace, NSWorkspace.didWakeNotification) { [weak self] in self?.isAsleep = false }
        on(workspace, NSWorkspace.screensDidSleepNotification) { [weak self] in self?.isAsleep = true }
        on(workspace, NSWorkspace.screensDidWakeNotification) { [weak self] in self?.isAsleep = false }
        on(workspace, NSWorkspace.sessionDidResignActiveNotification) { [weak self] in self?.isLocked = true }
        on(workspace, NSWorkspace.sessionDidBecomeActiveNotification) { [weak self] in self?.isLocked = false }
    }

    /// Seconds since the last keyboard, mouse, or trackpad event anywhere in the session.
    var idleSeconds: TimeInterval {
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: Self.anyInputEvent)
    }

    var isAway: Bool {
        isLocked || isAsleep || isScreenSaving || idleSeconds >= Self.idleThreshold
    }

    /// kCGAnyInputEventType isn't exported to Swift; its value is ~0.
    private static let anyInputEvent = CGEventType(rawValue: ~0) ?? .null
}
