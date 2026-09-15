import Foundation

/// Fixed-answer sources for snapshot rendering and tests.
final class StaticActivitySource: ActivitySource {
    var current: ResolvedActivity?
    init(_ current: ResolvedActivity? = nil) { self.current = current }
    func start() {}
    func refresh() {}
}

final class StaticAwayDetector: AwayDetector {
    var isAway: Bool
    init(isAway: Bool = false) { self.isAway = isAway }
    func start() {}
}
