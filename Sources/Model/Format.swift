import Foundation

enum Format {
    /// "0:54", "3:00", "1:01:01" — seconds are floored so a row never shows time it hasn't earned.
    static func duration(_ seconds: Double) -> String {
        let s = Int(max(seconds, 0).rounded(.down))
        if s >= 3600 {
            return String(format: "%d:%02d:%02d", s / 3600, (s / 60) % 60, s % 60)
        }
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    static func daysText(_ count: Int) -> String {
        count == 1 ? "1 DAY" : "\(count) DAYS"
    }

    /// Local calendar day, e.g. "2026-09-15". Used as the key for a day's record.
    static func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
        let f = dayKeyFormatter
        f.calendar = calendar
        f.timeZone = calendar.timeZone
        return f.string(from: date)
    }

    /// "TODAY" for the current day, otherwise "SEP 14" (localized month, uppercased).
    static func dayLabel(key: String, todayKey: String) -> String {
        if key == todayKey { return "TODAY" }
        guard let date = dayKeyFormatter.date(from: key) else { return key.uppercased() }
        return dayLabelFormatter.string(from: date).uppercased()
    }

    private static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let dayLabelFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.setLocalizedDateFormatFromTemplate("MMM d")
        return f
    }()
}
