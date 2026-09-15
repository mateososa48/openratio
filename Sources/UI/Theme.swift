import SwiftUI
import AppKit

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255)
    }
}

extension NSColor {
    convenience init(hex: UInt32) {
        self.init(srgbRed: CGFloat((hex >> 16) & 0xff) / 255,
                  green: CGFloat((hex >> 8) & 0xff) / 255,
                  blue: CGFloat(hex & 0xff) / 255, alpha: 1)
    }
}

/// Colors that don't change with the panel theme.
enum Palette {
    static let green = Color(hex: 0x28cd41)
    static let red = Color(hex: 0xff3b30)
    static let orange = Color(hex: 0xff9f0a)
    static let gray = Color(hex: 0x808080)      // tracking label + total
    static let dim = Color(hex: 0x666666)       // the unselected arrow once a row is classified
    static let historyDay = Color(hex: 0x888888)
    static let badgeText = Color(hex: 0x222222)

    static let nsGreen = NSColor(hex: 0x28cd41)
    static let nsRed = NSColor(hex: 0xff3b30)
    static let nsOrange = NSColor(hex: 0xff9f0a)
}

struct PanelTheme: Equatable {
    let isDark: Bool
    let background: Color
    let foreground: Color
    let border: Color
    let currentRowBackground: Color
    let arrowSelectedBackground: Color
    let arrowHoverBackground: Color
    let footerSelectedBackground: Color
    let footerHoverBackground: Color
    let footerHoverForeground: Color

    static let dark = PanelTheme(
        isDark: true,
        background: Color(hex: 0x0f0f0f),
        foreground: Color(hex: 0xf5f5f5),
        border: Color(hex: 0x242424),
        currentRowBackground: Color(hex: 0x1a1a1a),
        arrowSelectedBackground: Color(hex: 0x131313),
        arrowHoverBackground: Color(hex: 0x1a1a1a),
        footerSelectedBackground: Color(hex: 0x171717),
        footerHoverBackground: .white,
        footerHoverForeground: .black
    )

    static let light = PanelTheme(
        isDark: false,
        background: Color(hex: 0xf7f7f7),
        foreground: Color(hex: 0x111111),
        border: Color(hex: 0xcccccc),
        currentRowBackground: Color(hex: 0xe4e4e4),
        arrowSelectedBackground: Color(hex: 0xe8e8e8),
        arrowHoverBackground: Color(hex: 0xdddddd),
        footerSelectedBackground: Color(hex: 0xe8e8e8),
        footerHoverBackground: Color(hex: 0x111111),
        footerHoverForeground: .white
    )

    static func resolve(_ theme: Theme) -> PanelTheme {
        theme == .dark ? .dark : .light
    }
}

enum Metrics {
    static let panelWidth: CGFloat = 360
    static let panelHeight: CGFloat = 352
    static let caretHeight: CGFloat = 10
    static let caretHalfWidth: CGFloat = 10
    static let cornerRadius: CGFloat = 8
    static let rowHeight: CGFloat = 44
    static let listHeight: CGFloat = 220
    static let fontSize: CGFloat = 12

    /// One device pixel: 0.5pt on Retina, 1pt otherwise.
    static var hairline: CGFloat {
        1 / max(NSScreen.main?.backingScaleFactor ?? 2, 1)
    }

    static let font = Font.system(size: fontSize, design: .monospaced)
}

private struct PanelThemeKey: EnvironmentKey {
    static let defaultValue = PanelTheme.dark
}

extension EnvironmentValues {
    var panelTheme: PanelTheme {
        get { self[PanelThemeKey.self] }
        set { self[PanelThemeKey.self] = newValue }
    }
}

/// A one-pixel rule in the theme's border color.
struct Hairline: View {
    enum Axis { case horizontal, vertical }
    var axis: Axis = .horizontal
    var color: Color? = nil
    @Environment(\.panelTheme) private var theme

    var body: some View {
        Rectangle()
            .fill(color ?? theme.border)
            .frame(width: axis == .vertical ? Metrics.hairline : nil,
                   height: axis == .horizontal ? Metrics.hairline : nil)
    }
}

/// Buttons in the panel draw their own hover states; the system style must stay out of the way.
struct BareButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.contentShape(Rectangle())
    }
}
