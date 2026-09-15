# Split — project notes for AI assistants

Free, open-source macOS menu bar app: tracks create vs consume time and shows the ratio in the
menu bar. A 1:1 reimplementation of the UI/UX of Ratio (ratio.visualizevalue.com), built from
measurements of that site's demo (its CSS and page source), not from its code.

## Commands

- `make` — Release build to `build/Split.app`. Uses `DEVELOPER_DIR=/Applications/Xcode.app/...`
  automatically when `xcode-select` points at the Command Line Tools (this machine).
- `make run` — kill running instance, build, launch.
- `make test` — XCTest via `xcodebuild test` (16 tests in `Tests/SplitTests.swift`).
- `make snapshots` — renders every panel state to `build/snapshots/*.png` with fixture data
  (`Split --snapshot <dir>`). **Use this for visual QA**; it needs no screen-recording permission.
- `make project` / `xcodegen generate` — regenerate `Split.xcodeproj` from `project.yml` after
  adding files. The `.xcodeproj` is committed so people without XcodeGen can build.
- `python3 scripts/make_icon.py` — regenerate the app icon PNGs.

## Layout

See README "Architecture". Key seams:

- `Tracker` is the engine and the single `ObservableObject` the UI observes. It takes protocols
  (`ActivitySource`, `AwayDetector`) and an injectable clock so tests and snapshots drive it
  deterministically (`StaticSources.swift`). Tick logic is in `tick()`; never add AppKit there.
- `ActiveContext` + `BrowserURLProvider` resolve the frontmost app. Browser tab URLs come from
  Apple Events (`NSAppleScript` on a serial background queue). Firefox has no scripting bridge.
- `PanelController` owns a borderless `.nonactivatingPanel` under the status item; it closes on
  resign-key, Escape, and a global mouse-down monitor. The caret is drawn by `PanelShape`.
- `StatusItemController` sets an attributed title (`↑ 67/33`); left click toggles the panel,
  right click shows the utility menu.
- `main.swift` skips the `AppDelegate` when running as an XCTest host so tests never touch the
  real data file.

## Design tokens (measured from the reference)

Panel 360×352 + 10 pt caret. Rows 44 pt. SF Mono 12. Hairline = 1 device px.
Dark: bg `#0f0f0f`, fg `#f5f5f5`, border `#242424`, current row `#1a1a1a`, selected arrow
`#131313`, hover `#1a1a1a`, footer selected `#171717`, footer hover white-on-black inverted.
Light: bg `#f7f7f7`, fg `#111`, border `#ccc`, current row `#e4e4e4`, selected `#e8e8e8`,
hover `#ddd`. Green `#28cd41`, red `#ff3b30`, orange `#ff9f0a`, label gray `#808080`,
dimmed arrow `#666`, history day `#888`. Percent text is two decimals; menu bar and bars use
whole percents; consume is always the exact complement of create.

## Behavior rules worth knowing

- Idle ≥ 60 s, screen lock, sleep, or screensaver → AWAY (no attribution). Pause is manual.
- Elapsed time per tick is capped at 2 s so sleep gaps never inflate a row.
- Rows: current app first, then most recently used. Unclassified rows are orange.
- Day rollover happens on the first tick after local midnight; history keeps 365 days.
- RESET snapshots today and shows UNDO for 8 s.
- First launch opens the panel once (`settings.hasLaunchedBefore`).

## Gotchas

- A full menu bar on a notched Mac makes macOS hide new items: their window is parked under the
  notch or stacked on the clock's window. `PanelController.visibleFrame(of:)` detects both (aux
  areas + overlap with another process's status-bar-level window via `CGWindowListCopyWindowInfo`)
  and the panel then anchors to the top-right corner; `AppDelegate.warnIfItemHidden` explains it
  once on first launch. `SPLIT_DEBUG=1 build/Split.app/Contents/MacOS/Split` logs the anchor math.

- Ad-hoc signing (`CODE_SIGN_IDENTITY=-`) means macOS re-prompts browser automation consent after
  each rebuild. Real releases need a Developer ID + notarization (`SIGNING_IDENTITY` in Makefile).
- Hardened Runtime is on, so the `com.apple.security.automation.apple-events` entitlement is
  required for browser URLs. Don't remove it.
- The app is `LSUIElement`; there is no Dock icon and no main window. `About` activates the app
  temporarily.
- Naming: "Split" is a working name chosen to avoid shipping under Visualize Value's "Ratio"
  mark. Renaming touches `project.yml` (name, bundle id), `Store.defaultDirectory`, and strings in
  `StatusItemController`/`README`.
