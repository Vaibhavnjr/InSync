import CoreGraphics
import ImageIO
import SwiftUI
import WidgetKit

struct InSyncWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: InSyncWidgetEntry

    var body: some View {
        ZStack {
            Color.white

            if entry.isPreview {
                previewView
            } else if let imageData = entry.imageData,
               let image = Self.cgImage(from: imageData) {
                loadedView(image)
            } else {
                emptyView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(Color.insyncInk)
        .widgetURL(URL(string: "insync://open"))
        .containerBackground(Color.white, for: .widget)
        .widgetAccentable(false)
        .unredacted()
    }

    private func loadedView(_ image: CGImage) -> some View {
        Image(decorative: image, scale: 1, orientation: .up)
            .resizable()
            .interpolation(.high)
            .insyncFullColorWidgetImage()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
    }

    private var previewView: some View {
        SampleDoodleView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .widgetAccentable(false)
            .clipped()
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.square")
                .font(.system(size: family == .systemSmall ? 28 : 38, weight: .semibold))
                .foregroundStyle(Color.insyncInk.opacity(0.8))

            Text("No drawing yet")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("Open InSync and save a drawing.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(14)
    }

    private static func cgImage(from imageData: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            return nil
        }

        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}

private extension Image {
    @ViewBuilder
    func insyncFullColorWidgetImage() -> some View {
        if #available(macOS 15.0, *) {
            self.widgetAccentedRenderingMode(.fullColor)
                .widgetAccentable(false)
        } else {
            self.widgetAccentable(false)
        }
    }
}

private struct SampleDoodleView: View {
    var body: some View {
        GeometryReader { proxy in
            let scale = min(
                proxy.size.width / Constants.canvasSize.width,
                proxy.size.height / Constants.canvasSize.height
            )
            let drawingSize = CGSize(
                width: Constants.canvasSize.width * scale,
                height: Constants.canvasSize.height * scale
            )
            let origin = CGPoint(
                x: (proxy.size.width - drawingSize.width) / 2,
                y: (proxy.size.height - drawingSize.height) / 2
            )

            ZStack {
                path(
                    points: [
                        CGPoint(x: 118, y: 222),
                        CGPoint(x: 138, y: 178),
                        CGPoint(x: 182, y: 154),
                        CGPoint(x: 224, y: 178),
                        CGPoint(x: 250, y: 224),
                        CGPoint(x: 226, y: 270),
                        CGPoint(x: 184, y: 300),
                        CGPoint(x: 140, y: 268),
                        CGPoint(x: 118, y: 222)
                    ],
                    origin: origin,
                    scale: scale
                )
                .stroke(
                    Color.insyncInk,
                    style: StrokeStyle(lineWidth: 12 * scale, lineCap: .round, lineJoin: .round)
                )

                path(
                    points: [
                        CGPoint(x: 304, y: 252),
                        CGPoint(x: 400, y: 156),
                        CGPoint(x: 352, y: 204),
                        CGPoint(x: 400, y: 252),
                        CGPoint(x: 304, y: 156)
                    ],
                    origin: origin,
                    scale: scale
                )
                .stroke(
                    Color.insyncSoftPink,
                    style: StrokeStyle(lineWidth: 12 * scale, lineCap: .round, lineJoin: .round)
                )

                path(
                    points: [
                        CGPoint(x: 70, y: 90),
                        CGPoint(x: 150, y: 58),
                        CGPoint(x: 242, y: 82),
                        CGPoint(x: 332, y: 110),
                        CGPoint(x: 442, y: 92)
                    ],
                    origin: origin,
                    scale: scale
                )
                .stroke(
                    Color(hex: "#3D7BFF"),
                    style: StrokeStyle(lineWidth: 8 * scale, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .accessibilityHidden(true)
    }

    private func path(points: [CGPoint], origin: CGPoint, scale: CGFloat) -> Path {
        Path { path in
            guard let firstPoint = points.first else {
                return
            }

            path.move(to: transform(firstPoint, origin: origin, scale: scale))
            for point in points.dropFirst() {
                path.addLine(to: transform(point, origin: origin, scale: scale))
            }
        }
    }

    private func transform(_ point: CGPoint, origin: CGPoint, scale: CGFloat) -> CGPoint {
        CGPoint(x: origin.x + point.x * scale, y: origin.y + point.y * scale)
    }
}
