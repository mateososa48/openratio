import Foundation

/// How a tracked activity counts toward the ratio. Categories are global: classify once, it sticks.
enum Category: String, Codable {
    case create
    case consume
}

enum Theme: String, Codable {
    case dark
    case light
}

/// One tracked thing for one day: an app (keyed by bundle id) or a website (keyed by `web:<host>`).
struct Activity: Codable, Identifiable, Equatable {
    var key: String
    var name: String
    var seconds: Double
    var lastUsed: Date?

    var id: String { key }
}

struct DayRecord: Codable, Equatable {
    var activities: [String: Activity] = [:]

    var totalSeconds: Double {
        activities.values.reduce(0) { $0 + $1.seconds }
    }

    func seconds(for category: Category, categories: [String: Category]) -> Double {
        activities.values.reduce(0) { sum, activity in
            categories[activity.key] == category ? sum + activity.seconds : sum
        }
    }
}

struct Settings: Codable, Equatable {
    var theme: Theme = .dark
    var hasLaunchedBefore = false

    init() {}

    private enum CodingKeys: String, CodingKey { case theme, hasLaunchedBefore }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        theme = try c.decodeIfPresent(Theme.self, forKey: .theme) ?? .dark
        hasLaunchedBefore = try c.decodeIfPresent(Bool.self, forKey: .hasLaunchedBefore) ?? false
    }
}

/// Everything persisted to disk. Tolerant decoding so older files keep loading as fields are added.
struct StoreData: Codable, Equatable {
    static let currentVersion = 1

    var version = StoreData.currentVersion
    var categories: [String: Category] = [:]
    var days: [String: DayRecord] = [:]
    var settings = Settings()

    init() {}

    private enum CodingKeys: String, CodingKey { case version, categories, days, settings }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decodeIfPresent(Int.self, forKey: .version) ?? StoreData.currentVersion
        categories = try c.decodeIfPresent([String: Category].self, forKey: .categories) ?? [:]
        days = try c.decodeIfPresent([String: DayRecord].self, forKey: .days) ?? [:]
        settings = try c.decodeIfPresent(Settings.self, forKey: .settings) ?? Settings()
    }
}
