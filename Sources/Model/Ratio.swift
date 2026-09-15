import Foundation

/// The create/consume math, isolated so it is trivially testable.
/// Rounding mirrors the reference UI: whole percents for the menu bar and bars,
/// two decimals for the summary, with consume always the exact complement of create.
struct RatioSummary: Equatable {
    let createSeconds: Double
    let consumeSeconds: Double

    var hasData: Bool { createSeconds + consumeSeconds > 0 }

    /// 0...100, rounded to a whole number.
    var createPercent: Int {
        guard hasData else { return 0 }
        return Int((createSeconds / (createSeconds + consumeSeconds) * 100).rounded())
    }

    var consumePercent: Int { 100 - createPercent }

    /// "66.75%" or "—" when nothing has been categorized yet.
    var createPercentText: String {
        hasData ? String(format: "%.2f%%", Double(basisPoints) / 100) : "—"
    }

    var consumePercentText: String {
        hasData ? String(format: "%.2f%%", Double(10_000 - basisPoints) / 100) : "—"
    }

    /// "67/33" or "—/—". This is what the menu bar shows.
    var ratioText: String {
        hasData ? "\(createPercent)/\(consumePercent)" : "—/—"
    }

    private var basisPoints: Int {
        Int((createSeconds / (createSeconds + consumeSeconds) * 10_000).rounded())
    }
}
