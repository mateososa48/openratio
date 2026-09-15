import SwiftUI

/// Rounded panel body with a caret on top pointing at the menu bar item.
struct PanelShape: InsettableShape {
    var caretX: CGFloat
    var caretHeight: CGFloat = Metrics.caretHeight
    var caretHalfWidth: CGFloat = Metrics.caretHalfWidth
    var radius: CGFloat = Metrics.cornerRadius
    var insetAmount: CGFloat = 0

    func inset(by amount: CGFloat) -> PanelShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let body = CGRect(x: r.minX, y: r.minY + caretHeight, width: r.width, height: r.height - caretHeight)
        let cx = min(max(caretX, body.minX + radius + caretHalfWidth), body.maxX - radius - caretHalfWidth)
        let tipRounding: CGFloat = 1.5

        var p = Path()
        p.move(to: CGPoint(x: body.minX + radius, y: body.minY))
        p.addLine(to: CGPoint(x: cx - caretHalfWidth, y: body.minY))
        p.addLine(to: CGPoint(x: cx - tipRounding, y: r.minY + tipRounding))
        p.addQuadCurve(to: CGPoint(x: cx + tipRounding, y: r.minY + tipRounding),
                       control: CGPoint(x: cx, y: r.minY))
        p.addLine(to: CGPoint(x: cx + caretHalfWidth, y: body.minY))
        p.addLine(to: CGPoint(x: body.maxX - radius, y: body.minY))
        p.addArc(center: CGPoint(x: body.maxX - radius, y: body.minY + radius), radius: radius,
                 startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: body.maxX, y: body.maxY - radius))
        p.addArc(center: CGPoint(x: body.maxX - radius, y: body.maxY - radius), radius: radius,
                 startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: body.minX + radius, y: body.maxY))
        p.addArc(center: CGPoint(x: body.minX + radius, y: body.maxY - radius), radius: radius,
                 startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.addLine(to: CGPoint(x: body.minX, y: body.minY + radius))
        p.addArc(center: CGPoint(x: body.minX + radius, y: body.minY + radius), radius: radius,
                 startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.closeSubpath()
        return p
    }
}
