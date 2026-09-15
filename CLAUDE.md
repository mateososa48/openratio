# OpenRatio — project notes for AI assistants

Free, open-source macOS menu bar app: tracks create vs consume time and shows the ratio in the
menu bar. A 1:1 reimplementation of the UI/UX of Ratio (ratio.visualizevalue.com), built from
measurements of that site's demo (its CSS and page source), not from its code.

## Commands

- `make` — Release build to `build/OpenRatio.app`. Uses `DEVELOPER_DIR=/Applications/Xcode.app/...`
  automatically when `xcode-select` points at the Command Line Tools (this machine).
- `make run` — kill running instance, build, launch.
- `make test` — XCTest via `xcodebuild test` (16 tests in `Tests/OpenRatioTests.swift`).
- `make snapshots` — renders every panel state to `build/snapshots/*.png` with fixture data
  (`OpenRatio --snapshot <dir>`). **Use this for visual QA**; it needs no screen-recording permission.
- `make project` / `xcodegen generate` — regenerate `OpenRatio.xcodeproj` from `project.yml` after
  adding files. The `.xcodeproj` is committed so people without XcodeGen can build.
- `python3 scripts/make_icon.py` — regenerate the app icon PNGs.

## The landing page (`site/`)

Next.js 16 + React 19 + Tailwind v4 (CSS-first `@theme` in `app/globals.css`), deployed on Vercel
with root directory `site`. `npm run dev` from `site/`.

- **Design tokens are copied from the app**, not invented: `app/globals.css` mirrors
  `Sources/UI/Theme.swift`. If you change a color in the app, change it there too.
- `components/panel.tsx` is a faithful React replica of the real panel, 360x352 on a 44px row.
  `lib/ratio.ts` duplicates `Ratio.swift` and `Format.swift` arithmetic, including the rounding
  (two decimals in the summary, whole percents in the menu bar, consume is the exact complement).
- `lib/demo.ts` holds the demo rows. **These must stay in sync with the fixtures in
  `Sources/App/Snapshotter.swift`**, because `site/public/shots/*.png` are rendered from the app
  via `make snapshots`. If you change one, regenerate the other or the page contradicts itself.
- State is shared between the fixed nav readout and the panel through a small zustand store
  (`lib/store.ts`), which is what makes classifying a row move the menu bar number.
- Third-party: `@kitlangton/rolling-number` (the animated ratio digits), `motion` (scroll reveals
  and the ratio bar), `lucide-react` (same icon family the app draws). The FAQ uses native
  `<details>` rather than a component library: it gets keyboard and screen reader behaviour for
  free and suits the flat ruled surface.
- **Never use an `rn-` prefixed class name.** Rolling Number owns that namespace and positions
  `.rn-slot` absolutely; a collision throws the digits into the top-left corner of the page.
- `public/OpenRatio.zip` is the actual shipped build. Refresh it with
  `ditto -c -k --keepParent build/OpenRatio.app site/public/OpenRatio.zip` after changing the app.

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

## Distribution

- `make dmg` builds the styled disk image with **dmgbuild** (`pip3 install dmgbuild`), not Finder
  scripting, so it works the same on a laptop and on a headless CI runner. Layout lives in
  `scripts/dmg_settings.py`; the window is 660x420 with the app at (170,190) and the Applications
  alias at (490,190).
- `Resources/dmg/background.tiff` is committed. `make dmg` only regenerates it when it is missing,
  so building the app does not require Pillow. Use `make dmg-background` after editing
  `scripts/make_dmg_background.py`.
- **The disk image background is light on purpose.** Finder paints icon labels in the system label
  colour, which a background image cannot override, so on a dark ground "OpenRatio" and
  "Applications" render near-black on near-black (measured 1.3:1). Known trade-off: in Dark Mode
  those labels go light-on-light instead.
- Homebrew tap lives in a separate repo, `mateososa48/homebrew-openratio`, because taps must be
  named `homebrew-*`. The cask points at the GitHub release asset, so cutting a release means
  bumping `version` and `sha256` in the cask too.
- **Homebrew 6 removed `--no-quarantine`** and ignores it in `HOMEBREW_CASK_OPTS` (verified, not
  assumed). The cask does not strip the attribute in a postflight; it prints the `xattr` command in
  `caveats` and lets the user decide. Do not "fix" this by adding a postflight.
- Only notarization removes the Gatekeeper dialog, and that needs a paid Apple Developer account.

## Gotchas

- A full menu bar on a notched Mac makes macOS hide new items: their window is parked under the
  notch or stacked on the clock's window. `PanelController.visibleFrame(of:)` detects both (aux
  areas + overlap with another process's status-bar-level window via `CGWindowListCopyWindowInfo`)
  and the panel then anchors to the top-right corner; `AppDelegate.warnIfItemHidden` explains it
  once on first launch. `OPENRATIO_DEBUG=1 build/OpenRatio.app/Contents/MacOS/OpenRatio` logs the anchor math.

- Ad-hoc signing (`CODE_SIGN_IDENTITY=-`) means macOS re-prompts browser automation consent after
  each rebuild. Real releases need a Developer ID + notarization (`SIGNING_IDENTITY` in Makefile).
- Hardened Runtime is on, so the `com.apple.security.automation.apple-events` entitlement is
  required for browser URLs. Don't remove it.
- The app is `LSUIElement`; there is no Dock icon and no main window. `About` activates the app
  temporarily.
- Naming: "OpenRatio" is a working name chosen to avoid shipping under Visualize Value's "Ratio"
  mark. Renaming touches `project.yml` (name, bundle id), `Store.defaultDirectory`, and strings in
  `StatusItemController`/`README`.
