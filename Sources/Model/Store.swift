import Foundation

/// JSON persistence in ~/Library/Application Support/Split/data.json.
/// Writes are atomic; a file that fails to decode is moved aside, never overwritten.
final class Store {
    private(set) var data: StoreData
    let fileURL: URL
    private var dirty = false

    static func defaultDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent("Split", isDirectory: true)
    }

    init(directory: URL = Store.defaultDirectory()) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("data.json")
        data = Store.load(from: fileURL)
    }

    func update(_ change: (inout StoreData) -> Void) {
        change(&data)
        dirty = true
    }

    func saveIfNeeded() {
        if dirty { save() }
    }

    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(data).write(to: fileURL, options: .atomic)
            dirty = false
        } catch {
            NSLog("Split: failed to save \(fileURL.lastPathComponent): \(error)")
        }
    }

    private static func load(from url: URL) -> StoreData {
        guard let raw = try? Data(contentsOf: url) else { return StoreData() }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode(StoreData.self, from: raw) {
            return decoded
        }
        let backup = url.deletingPathExtension()
            .appendingPathExtension("corrupt-\(Int(Date().timeIntervalSince1970)).json")
        try? FileManager.default.moveItem(at: url, to: backup)
        NSLog("Split: could not read data.json, moved it to \(backup.lastPathComponent) and started fresh")
        return StoreData()
    }
}
