import SwiftUI

/// Lucide icons (ISC license, lucide.dev) drawn as paths on a 24pt grid, rendered at 14pt.
/// Kept in code so the app has no asset-catalog dependency for glyphs.
struct LucideIcon: View {
    enum Kind { case pause, play, history, arrowLeft, sun, moon }

    let kind: Kind
    var size: CGFloat = 14

    init(_ kind: Kind, size: CGFloat = 14) {
        self.kind = kind
        self.size = size
    }

    var body: some View {
        let scale = size / 24
        Self.path(for: kind)
            .applying(CGAffineTransform(scaleX: scale, y: scale))
            .stroke(style: StrokeStyle(lineWidth: 2 * scale, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
    }

    static func path(for kind: Kind) -> Path {
        var p = Path()
        switch kind {
        case .pause:
            p.addRoundedRect(in: CGRect(x: 14, y: 3, width: 5, height: 18), cornerSize: CGSize(width: 1, height: 1))
            p.addRoundedRect(in: CGRect(x: 5, y: 3, width: 5, height: 18), cornerSize: CGSize(width: 1, height: 1))
        case .play:
            p.move(to: CGPoint(x: 6, y: 4.5))
            p.addLine(to: CGPoint(x: 19.5, y: 12))
            p.addLine(to: CGPoint(x: 6, y: 19.5))
            p.closeSubpath()
        case .history:
            // rotate-ccw-clock: a 315° arc, an arrow head at the top-left, and clock hands.
            p.addArc(center: CGPoint(x: 12, y: 12), radius: 9,
                     startAngle: .degrees(180), endAngle: .degrees(-137), clockwise: true)
            p.addLine(to: CGPoint(x: 3, y: 8))
            p.move(to: CGPoint(x: 3, y: 3))
            p.addLine(to: CGPoint(x: 3, y: 8))
            p.addLine(to: CGPoint(x: 8, y: 8))
            p.move(to: CGPoint(x: 12, y: 7))
            p.addLine(to: CGPoint(x: 12, y: 12))
            p.addLine(to: CGPoint(x: 16, y: 14))
        case .arrowLeft:
            p.move(to: CGPoint(x: 12, y: 19))
            p.addLine(to: CGPoint(x: 5, y: 12))
            p.addLine(to: CGPoint(x: 12, y: 5))
            p.move(to: CGPoint(x: 19, y: 12))
            p.addLine(to: CGPoint(x: 5, y: 12))
        case .sun:
            p.addEllipse(in: CGRect(x: 8, y: 8, width: 8, height: 8))
            let rays: [(CGPoint, CGPoint)] = [
                (CGPoint(x: 12, y: 2), CGPoint(x: 12, y: 4)),
                (CGPoint(x: 12, y: 20), CGPoint(x: 12, y: 22)),
                (CGPoint(x: 4.93, y: 4.93), CGPoint(x: 6.34, y: 6.34)),
                (CGPoint(x: 17.66, y: 17.66), CGPoint(x: 19.07, y: 19.07)),
                (CGPoint(x: 2, y: 12), CGPoint(x: 4, y: 12)),
                (CGPoint(x: 20, y: 12), CGPoint(x: 22, y: 12)),
                (CGPoint(x: 6.34, y: 17.66), CGPoint(x: 4.93, y: 19.07)),
                (CGPoint(x: 19.07, y: 4.93), CGPoint(x: 17.66, y: 6.34)),
            ]
            for (a, b) in rays {
                p.move(to: a)
                p.addLine(to: b)
            }
        case .moon:
            p.move(to: CGPoint(x: 20.985, y: 12.486))
            p.addArc(center: CGPoint(x: 12, y: 12), radius: 9,
                     startAngle: .degrees(3.1), endAngle: .degrees(266.9), clockwise: false)
            p.addArc(center: CGPoint(x: 17, y: 7), radius: 6,
                     startAngle: .degrees(212), endAngle: .degrees(58), clockwise: true)
            p.closeSubpath()
        }
        return p
    }
}
