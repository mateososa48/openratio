import AppKit

// `OpenRatio --snapshot <dir>` renders every panel state to PNG and exits. Used for the README
// and for visual QA without needing screen-recording permission.
if let index = CommandLine.arguments.firstIndex(of: "--snapshot"), index + 1 < CommandLine.arguments.count {
    _ = NSApplication.shared
    Snapshotter.run(directory: URL(fileURLWithPath: CommandLine.arguments[index + 1]))
    exit(0)
}

let app = NSApplication.shared
// Under XCTest the app is only a host for the test bundle: don't start tracking or touch the real data file.
let isTestHost = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    || NSClassFromString("XCTestCase") != nil
let delegate = isTestHost ? nil : AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
