import SwiftUI
import AppKit

struct DrawingCanvasView: View {
    @Binding var strokes: [Stroke]

    let baseImageData: Data?
    let selectedColorHex: String
    let tool: DrawingTool
    let canvasBackgroundHex: String
    let onBucketFill: (CGPoint) -> Void

    @State private var activeStrokeID: UUID?
    @State private var didFillWithBucket = false

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(Color(hex: canvasBackgroundHex))
                )

                if let baseImageData,
                   let image = NSImage(data: baseImageData) {
                    context.draw(
                        Image(nsImage: image),
                        in: CGRect(origin: .zero, size: size)
                    )
                }

                for stroke in strokes {
                    draw(stroke, in: &context, canvasSize: size)
                }
            }
            .background(Color(hex: canvasBackgroundHex))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color(hex: "#D4D2D1").opacity(0.55), lineWidth: 1)
            )
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        appendPoint(value.location, in: proxy.size)
                    }
                    .onEnded { _ in
                        activeStrokeID = nil
                        didFillWithBucket = false
                    }
            )
        }
        .aspectRatio(Constants.canvasSize.width / Constants.canvasSize.height, contentMode: .fit)
        .accessibilityLabel("Drawing canvas")
    }

    private func draw(_ stroke: Stroke, in context: inout GraphicsContext, canvasSize: CGSize) {
        guard let firstModelPoint = stroke.points.first else { return }

        let color = Color(hex: stroke.isEraser ? canvasBackgroundHex : stroke.colorHex)
        let scale = canvasScale(for: canvasSize)
        let firstPoint = viewPoint(for: firstModelPoint, in: canvasSize)
        let lineWidth = stroke.lineWidth * scale

        if stroke.points.count == 1 {
            let radius = lineWidth / 2
            let rect = CGRect(
                x: firstPoint.x - radius,
                y: firstPoint.y - radius,
                width: lineWidth,
                height: lineWidth
            )
            context.fill(Path(ellipseIn: rect), with: .color(color))
            return
        }

        var path = Path()
        path.move(to: firstPoint)

        for point in stroke.points.dropFirst() {
            path.addLine(to: viewPoint(for: point, in: canvasSize))
        }

        context.stroke(
            path,
            with: .color(color),
            style: StrokeStyle(
                lineWidth: lineWidth,
                lineCap: .round,
                lineJoin: .round
            )
        )
    }

    private func appendPoint(_ rawPoint: CGPoint, in size: CGSize) {
        let point = modelPoint(for: rawPoint, in: size)

        if tool == .bucket {
            if !didFillWithBucket {
                onBucketFill(point)
                didFillWithBucket = true
            }
            return
        }

        if let activeStrokeID,
           let index = strokes.firstIndex(where: { $0.id == activeStrokeID }) {
            strokes[index].points.append(point)
            return
        }

        let newStroke = Stroke(
            colorHex: selectedColorHex,
            points: [point],
            isEraser: tool == .eraser
        )
        activeStrokeID = newStroke.id
        strokes.append(newStroke)
    }

    private func modelPoint(for rawPoint: CGPoint, in size: CGSize) -> CGPoint {
        guard size.width > 0, size.height > 0 else { return .zero }

        let x = min(max(rawPoint.x / size.width * Constants.canvasSize.width, 0), Constants.canvasSize.width)
        let y = min(max(rawPoint.y / size.height * Constants.canvasSize.height, 0), Constants.canvasSize.height)
        return CGPoint(x: x, y: y)
    }

    private func viewPoint(for modelPoint: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: modelPoint.x / Constants.canvasSize.width * size.width,
            y: modelPoint.y / Constants.canvasSize.height * size.height
        )
    }

    private func canvasScale(for size: CGSize) -> CGFloat {
        min(
            size.width / Constants.canvasSize.width,
            size.height / Constants.canvasSize.height
        )
    }
}
