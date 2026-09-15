import SwiftUI

/// Positions the caret; owned by the panel controller and updated on every show.
final class PanelLayout: ObservableObject {
    @Published var caretX: CGFloat = Metrics.panelWidth / 2
}

/// The full popover: caret + rounded body + content, exactly 360×362 points.
struct PanelRoot: View {
    @ObservedObject var tracker: Tracker
    @ObservedObject var layout: PanelLayout

    var body: some View {
        let theme = PanelTheme.resolve(tracker.theme)
        let shape = PanelShape(caretX: layout.caretX)
        PanelView(tracker: tracker)
            .frame(width: Metrics.panelWidth, height: Metrics.panelHeight)
            .padding(.top, Metrics.caretHeight)
            .background(shape.fill(theme.background))
            .clipShape(shape)
            .overlay(shape.strokeBorder(theme.border, lineWidth: Metrics.hairline))
            .frame(width: Metrics.panelWidth, height: Metrics.panelHeight + Metrics.caretHeight)
            .environment(\.panelTheme, theme)
            .font(Metrics.font)
            .foregroundColor(theme.foreground)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Split activity tracker")
    }
}

struct PanelView: View {
    @ObservedObject var tracker: Tracker

    var body: some View {
        VStack(spacing: 0) {
            SummaryView(summary: tracker.summary)
            TrackingRowView(tracker: tracker)
            Group {
                if tracker.showHistory {
                    HistoryListView(days: tracker.history)
                } else {
                    ActivityListView(tracker: tracker)
                }
            }
            .frame(height: Metrics.listHeight)
            FooterView(tracker: tracker)
        }
    }
}

// MARK: - Summary

struct SummaryView: View {
    let summary: RatioSummary
    @Environment(\.panelTheme) private var theme

    var body: some View {
        HStack(spacing: 0) {
            cell(arrow: "↑", value: summary.createPercentText, color: Palette.green, label: "CREATING")
            cell(arrow: "↓", value: summary.consumePercentText, color: Palette.red, label: "CONSUMING")
        }
        .frame(height: Metrics.rowHeight)
        .overlay(alignment: .bottom) {
            // The bottom rule doubles as the ratio bar: red track, green fill.
            ZStack(alignment: .leading) {
                Rectangle().fill(Palette.red)
                Rectangle().fill(Palette.green)
                    .frame(width: Metrics.panelWidth * CGFloat(summary.createPercent) / 100)
            }
            .frame(height: Metrics.hairline)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(summary.hasData
            ? "\(summary.createPercent)% create, \(summary.consumePercent)% consume"
            : "No categorized time")
    }

    private func cell(arrow: String, value: String, color: Color, label: String) -> some View {
        (Text("\(arrow) \(value)").foregroundColor(color) + Text("\u{00A0}\(label)"))
            .lineLimit(1)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Tracking row / history heading

struct TrackingRowView: View {
    @ObservedObject var tracker: Tracker
    @Environment(\.panelTheme) private var theme

    var body: some View {
        HStack(spacing: 0) {
            Text(tracker.trackingLabel)
                .foregroundColor(Palette.gray)
                .lineLimit(1)
                .padding(.leading, 16)
                .frame(maxWidth: .infinity, alignment: .leading)

            if tracker.showHistory {
                Text(Format.daysText(tracker.history.count))
                    .foregroundColor(Palette.gray)
                    .monospacedDigit()
                    .padding(.trailing, 16)
                    .frame(width: 176, alignment: .trailing)
            } else {
                Text(Format.duration(tracker.totalSeconds))
                    .foregroundColor(Palette.gray)
                    .monospacedDigit()
                    .padding(.trailing, 8)
                    .frame(width: 92, alignment: .trailing)
                    .accessibilityLabel("Total tracked time \(Format.duration(tracker.totalSeconds))")
                pendingButton
            }
        }
        .frame(height: Metrics.rowHeight)
        .overlay(alignment: .bottom) { Hairline() }
    }

    private var pendingButton: some View {
        let count = tracker.pendingCount
        let inverted = tracker.pendingOnly && count == 0
        return Button(action: tracker.togglePendingOnly) {
            Group {
                if count > 0 {
                    AttentionBadge(count: count)
                } else {
                    Text("✓")
                }
            }
            .foregroundColor(inverted ? .black : theme.foreground)
            .frame(width: 88, height: Metrics.rowHeight)
            .background(inverted ? Color.white : Color.clear)
            .overlay(alignment: .leading) { Hairline(axis: .vertical) }
        }
        .buttonStyle(BareButtonStyle())
        .help(count > 0 ? "\(count) \(count == 1 ? "app needs" : "apps need") categorizing" : "All apps categorized")
        .accessibilityLabel(tracker.pendingOnly ? "Show all activity" : "Review \(count) uncategorized apps")
        .accessibilityAddTraits(tracker.pendingOnly ? .isSelected : [])
    }
}

struct AttentionBadge: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(Metrics.font.weight(.bold))
            .monospacedDigit()
            .foregroundColor(Palette.badgeText)
            .padding(.horizontal, 5)
            .frame(minWidth: 19, minHeight: 19, maxHeight: 19)
            .background(Capsule().fill(Palette.orange))
    }
}

// MARK: - Activity list

struct ActivityListView: View {
    @ObservedObject var tracker: Tracker

    var body: some View {
        let rows = tracker.rows
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                if rows.isEmpty {
                    Text("All caught up.")
                        .padding(EdgeInsets(top: 13, leading: 16, bottom: 13, trailing: 16))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(rows) { row in
                        ActivityRowView(row: row, isLive: tracker.isLive) { category in
                            tracker.classify(row.key, as: category)
                        }
                    }
                }
            }
        }
        .accessibilityLabel(tracker.pendingOnly ? "Uncategorized activity" : "Today's activity")
    }
}

struct ActivityRowView: View {
    let row: ActivityRow
    let isLive: Bool
    let classify: (Category) -> Void
    @Environment(\.panelTheme) private var theme

    var body: some View {
        HStack(spacing: 0) {
            Text(row.name)
                .fontWeight(row.isCurrent ? .semibold : .regular)
                .foregroundColor(row.category == nil ? Palette.orange : theme.foreground)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.leading, 16)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                if isLive && row.isCurrent {
                    Circle().fill(Palette.green).frame(width: 4, height: 4)
                        .accessibilityLabel("Currently tracking")
                }
                Text(Format.duration(row.seconds)).monospacedDigit()
            }
            .padding(.trailing, 8)
            .frame(width: 92, alignment: .trailing)

            ArrowButton(glyph: "↑", color: Palette.green, selected: row.category == .create,
                        dimmed: row.category == .consume) { classify(.create) }
                .help("Create")
                .accessibilityLabel("Categorize \(row.name) as create")
            ArrowButton(glyph: "↓", color: Palette.red, selected: row.category == .consume,
                        dimmed: row.category == .create) { classify(.consume) }
                .help("Consume")
                .accessibilityLabel("Categorize \(row.name) as consume")
        }
        .frame(height: Metrics.rowHeight)
        .background(row.isCurrent ? theme.currentRowBackground : Color.clear)
        .overlay(alignment: .bottom) { Hairline() }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(row.isCurrent ? .isSelected : [])
    }
}

struct ArrowButton: View {
    let glyph: String
    let color: Color
    let selected: Bool
    let dimmed: Bool
    let action: () -> Void
    @State private var hovering = false
    @Environment(\.panelTheme) private var theme

    var body: some View {
        Button(action: action) {
            Text(glyph)
                .fontWeight(selected ? .bold : .regular)
                .foregroundColor(dimmed ? Palette.dim : color)
                .frame(width: Metrics.rowHeight, height: Metrics.rowHeight)
                .background(hovering ? theme.arrowHoverBackground
                            : selected ? theme.arrowSelectedBackground : Color.clear)
                .overlay(alignment: .leading) { Hairline(axis: .vertical) }
        }
        .buttonStyle(BareButtonStyle())
        .onHover { hovering = $0 }
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

// MARK: - History

struct HistoryListView: View {
    let days: [HistoryDay]

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                ForEach(days) { day in
                    HistoryRowView(day: day)
                }
            }
        }
        .accessibilityLabel("Daily ratio history")
    }
}

struct HistoryRowView: View {
    let day: HistoryDay
    @Environment(\.panelTheme) private var theme

    private var valueColor: Color {
        guard day.summary.hasData else { return Palette.gray }
        if day.summary.createPercent > 50 { return Palette.green }
        if day.summary.createPercent < 50 { return Palette.red }
        return theme.foreground
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(day.label)
                .foregroundColor(Palette.historyDay)
                .lineLimit(1)
                .frame(width: 64, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(day.summary.hasData ? Palette.red : theme.border)
                    Rectangle().fill(Palette.green)
                        .frame(width: geo.size.width * CGFloat(day.summary.createPercent) / 100)
                }
            }
            .frame(height: 2)
            Text(day.summary.ratioText)
                .monospacedDigit()
                .foregroundColor(valueColor)
                .lineLimit(1)
                .frame(width: 62, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .frame(height: Metrics.rowHeight)
        .overlay(alignment: .bottom) { Hairline() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(day.label): \(day.summary.ratioText)")
    }
}

// MARK: - Footer

struct FooterView: View {
    @ObservedObject var tracker: Tracker
    @Environment(\.panelTheme) private var theme

    var body: some View {
        HStack(spacing: 0) {
            FooterButton(width: 44, leadingBorder: false, action: tracker.togglePause) {
                LucideIcon(tracker.isPaused ? .play : .pause)
            }
            .help(tracker.isPaused ? "Resume tracking" : "Pause tracking")
            .accessibilityLabel(tracker.isPaused ? "Resume tracking" : "Pause tracking")

            FooterButton(width: 44, selected: tracker.showHistory, action: tracker.toggleHistory) {
                LucideIcon(tracker.showHistory ? .arrowLeft : .history)
            }
            .help(tracker.showHistory ? "Back to activity" : "History")
            .accessibilityLabel(tracker.showHistory ? "Back to activity" : "Show history")

            FooterButton(hoverable: false, action: { tracker.canUndo ? tracker.undo() : tracker.reset() }) {
                Text(tracker.canUndo ? "UNDO" : "RESET")
            }
            .accessibilityLabel(tracker.canUndo ? "Undo reset" : "Reset today")

            FooterButton(action: { NSApp.terminate(nil) }) {
                Text("QUIT")
            }
            .accessibilityLabel("Quit Split")

            FooterButton(width: 44, action: tracker.toggleTheme) {
                LucideIcon(theme.isDark ? .sun : .moon)
            }
            .help(theme.isDark ? "Light mode" : "Dark mode")
            .accessibilityLabel(theme.isDark ? "Switch to light mode" : "Switch to dark mode")
        }
        .frame(height: Metrics.rowHeight)
        .overlay(alignment: .top) { Hairline() }
    }
}

struct FooterButton<Label: View>: View {
    var width: CGFloat? = nil
    var selected = false
    var hoverable = true
    var leadingBorder = true
    let action: () -> Void
    @ViewBuilder let label: () -> Label
    @State private var hovering = false
    @Environment(\.panelTheme) private var theme

    private var isHot: Bool { hovering && hoverable }

    var body: some View {
        Button(action: action) {
            label()
                .foregroundColor(isHot ? theme.footerHoverForeground : theme.foreground)
                .frame(maxWidth: width == nil ? .infinity : width, maxHeight: .infinity)
                .frame(width: width)
                .background(isHot ? theme.footerHoverBackground
                            : selected ? theme.footerSelectedBackground : Color.clear)
                .overlay(alignment: .leading) {
                    if leadingBorder { Hairline(axis: .vertical) }
                }
        }
        .buttonStyle(BareButtonStyle())
        .onHover { hovering = $0 }
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
