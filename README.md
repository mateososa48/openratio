# OpenRatio

**Create more. Consume less.** A free, open-source macOS menu bar app that tracks how much of
your screen time goes to *creating* versus *consuming*, and shows the ratio in your menu bar.

<p align="center">
  <img src="docs/screenshots/dark-activity.png" width="360" alt="OpenRatio panel, dark">
  &nbsp;&nbsp;
  <img src="docs/screenshots/light-activity.png" width="360" alt="OpenRatio panel, light">
</p>

OpenRatio watches which app (or which website, in your browser) is in front, and asks you one
question per app: is this **↑ create** or **↓ consume**? Answer once and it sticks. From then on
your menu bar reads `↑ 67/33` while you're making things and `↓ 41/59` when the feed wins.

Everything stays on your Mac. There is no account, no server, no analytics. Your data is one
JSON file you can open, edit, or delete.

## How it works

1. **It tracks the active window.** Every second, the frontmost app gets one more second. In
   Safari, Chrome, Arc, Brave, Edge, Vivaldi, Opera, or Dia the active tab's domain is tracked
   instead of the browser, so `x.com` and `github.com` are separate rows.
2. **Choose ↑ create or ↓ consume once.** Unclassified rows are orange; the badge in the tracking
   row counts them, and clicking it filters the list down to what still needs an answer.
3. **The menu bar ratio updates as you work.** Green arrow while you're in a create app, red
   while you're consuming, `?` for something you haven't classified, `Ⅱ` when you're away or paused.
4. **Away time isn't counted.** No input for 60 seconds, a locked screen, sleep, or the
   screensaver all pause attribution automatically. The pause button stops it on purpose.
5. **History shows your ratio over time.** One row per day, with a green/red bar and the split.

The footer has pause, history, **RESET** (undo is offered for 8 seconds), **QUIT**, and a
light/dark toggle. Right-click the menu bar item for *Launch at Login* and to reveal the data file.

Landing page and downloads: **[openratio.app](https://openratio.app)** (source in [`site/`](site)).

## Install

### Homebrew

```sh
brew install --cask mateososa48/openratio/openratio
xattr -dr com.apple.quarantine /Applications/OpenRatio.app
```

### Disk image

1. Download `OpenRatio-1.0.0.dmg` from the [latest release](../../releases/latest).
2. Open it and drag OpenRatio across to Applications.
3. The first launch is blocked. Open *System Settings*, go to *Privacy & Security*, scroll to the
   bottom, and click **Open Anyway**. You only do this once.

### Why the first launch is blocked

OpenRatio is ad-hoc signed and not notarized, because notarizing requires a paid Apple Developer
account. macOS blocks the first launch of any app in that state.

Homebrew used to offer `--no-quarantine` for exactly this. That flag was removed in Homebrew 6 and
the `HOMEBREW_CASK_OPTS` equivalent is ignored, so no install route avoids the block on its own.
The cask deliberately does not strip the quarantine attribute behind your back; it prints the
command instead. Building from source avoids the whole thing, since nothing is ever quarantined.

When you first switch to a browser, macOS also asks whether OpenRatio may control it. That is the
Apple Events permission used to read the active tab's address. Say yes to track sites separately;
say no and the browser is tracked as one app.

Requires macOS 13 Ventura or later. Apple silicon and Intel.

## The landing page

`site/` is a Next.js 16 app (App Router, React 19, Tailwind v4) deployed on Vercel. It embeds a
working React replica of the panel so visitors can classify rows and watch the ratio move before
downloading anything. The panel screenshots on the page are rendered by the app itself through
`make snapshots`, so they can never drift from the product.

```bash
cd site && npm install && npm run dev
```

## Architecture

Swift, AppKit for the shell, SwiftUI for the panel content. No dependencies.

```
Sources/
  App/         main.swift (entry + --snapshot), AppDelegate, Snapshotter (renders panel states to PNG)
  Model/       Models (Activity, DayRecord, StoreData), Ratio (the math), Format, Store (JSON persistence)
  Tracking/    Tracker (1 s tick loop, attribution, reset/undo, day rollover)
               ActiveContext (frontmost app → activity), BrowserURLProvider (Apple Events → tab host)
               IdleMonitor (idle / lock / sleep), LaunchAtLogin
  StatusBar/   StatusItemController (menu bar title + right-click menu)
               PanelController (borderless non-activating NSPanel positioned under the item)
  UI/          Theme (tokens), PanelShape (rounded body + caret), Icons (Lucide paths), PanelView
Tests/         XCTest: ratio math, formatting, tracker behavior, persistence
```

Data lives in `~/Library/Application Support/OpenRatio/data.json`:

```json
{
  "categories": { "com.todesktop.230313mzl4w4u92": "create", "web:x.com": "consume" },
  "days": { "2026-09-15": { "activities": { "web:x.com": { "key": "web:x.com", "name": "x.com", "seconds": 90, "lastUsed": "…" } } } },
  "settings": { "theme": "dark", "hasLaunchedBefore": true }
}
```

Apps are keyed by bundle identifier, websites by `web:<host>`. Categories are global, so a
classification applies to every day, past and future.

## Design

The panel is 360×352 pt, SF Mono 12 pt, 44 pt rows, one-device-pixel rules. Colors are Apple's
system green `#28cd41`, red `#ff3b30`, and orange `#ff9f0a` on `#0f0f0f` (dark) or `#f7f7f7`
(light). The look and interaction model follow [Ratio](https://ratio.visualizevalue.com) by
Visualize Value, whose demo is the reference this app was built against. OpenRatio is an independent
reimplementation and is not affiliated with Visualize Value.

## License

MIT. Icons are from [Lucide](https://lucide.dev) (ISC).
