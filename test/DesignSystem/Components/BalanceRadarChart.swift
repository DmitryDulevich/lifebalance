import SwiftUI

struct BalanceRadarChart: View {
    struct Axis: Identifiable {
        let id = UUID()
        let color: Color
        /// 1...10, or nil if not yet rated.
        let value: Int?
    }

    let axes: [Axis]
    private let ringCount = 5

    var body: some View {
        Canvas { context, size in
            guard axes.count >= 3 else { return }
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let maxRadius = min(size.width, size.height) / 2 - 10
            let angleStep = 2 * Double.pi / Double(axes.count)

            func point(at index: Int, radiusFraction: Double) -> CGPoint {
                let angle = -Double.pi / 2 + angleStep * Double(index)
                return CGPoint(
                    x: center.x + CGFloat(cos(angle)) * maxRadius * CGFloat(radiusFraction),
                    y: center.y + CGFloat(sin(angle)) * maxRadius * CGFloat(radiusFraction)
                )
            }

            for ring in 1...ringCount {
                let fraction = Double(ring) / Double(ringCount)
                var path = Path()
                for i in 0..<axes.count {
                    let p = point(at: i, radiusFraction: fraction)
                    if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
                }
                path.closeSubpath()
                context.stroke(path, with: .color(Palette.trackBackground), lineWidth: 1)
            }

            for i in 0..<axes.count {
                var spoke = Path()
                spoke.move(to: center)
                spoke.addLine(to: point(at: i, radiusFraction: 1))
                context.stroke(spoke, with: .color(Palette.trackBackground), lineWidth: 1)
            }

            var valuePath = Path()
            for (i, axis) in axes.enumerated() {
                let fraction = Double(axis.value ?? 0) / 10
                let p = point(at: i, radiusFraction: fraction)
                if i == 0 { valuePath.move(to: p) } else { valuePath.addLine(to: p) }
            }
            valuePath.closeSubpath()
            context.fill(valuePath, with: .color(Palette.accent.opacity(0.25)))
            context.stroke(valuePath, with: .color(Palette.accent), lineWidth: 2)

            for (i, axis) in axes.enumerated() {
                let fraction = Double(axis.value ?? 0) / 10
                let p = point(at: i, radiusFraction: fraction)
                let dotRect = CGRect(x: p.x - 4.5, y: p.y - 4.5, width: 9, height: 9)
                context.fill(Path(ellipseIn: dotRect), with: .color(axis.color))
            }
        }
    }
}
