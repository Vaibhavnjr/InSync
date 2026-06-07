import SwiftUI

struct DrawingView: View {
    @EnvironmentObject private var appState: AppState

    @State private var strokes: [Stroke] = []
    @State private var selectedColorHex = Constants.drawingColors[0].hex
    @State private var canvasBackgroundHex = Constants.defaultCanvasBackgroundHex
    @State private var flattenedCanvasData: Data?
    @State private var tool: DrawingTool = .brush
    @State private var isSending = false

    var body: some View {
        GeometryReader { proxy in
            let metrics = layoutMetrics(for: proxy.size)

            ZStack(alignment: .bottom) {
                VStack(spacing: metrics.stackSpacing) {
                    DrawingCanvasView(
                        strokes: $strokes,
                        baseImageData: flattenedCanvasData,
                        selectedColorHex: selectedColorHex,
                        tool: tool,
                        canvasBackgroundHex: canvasBackgroundHex,
                        onBucketFill: performBucketFill(at:)
                    )
                    .frame(width: metrics.canvasWidth, height: metrics.canvasHeight)

                    toolbar(scale: metrics.scale)
                }
                .frame(width: metrics.contentWidth)

                StatusTextView()
                    .frame(width: metrics.contentWidth)
                    .offset(y: metrics.statusOffset)
            }
            .frame(width: metrics.contentWidth, height: metrics.contentHeight, alignment: .top)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.horizontal, metrics.horizontalPadding)
            .padding(.top, metrics.topPadding)
            .padding(.bottom, metrics.bottomPadding)
        }
    }

    private func toolbar(scale: CGFloat) -> some View {
        HStack(spacing: 0) {
            colorControls
                .frame(width: 272, height: 32)

            Spacer(minLength: 0)

            Rectangle()
                .fill(Color(hex: "#D4D2D1").opacity(0.4))
                .frame(width: 1, height: 17)

            Spacer(minLength: 0)

            toolControls
                .frame(width: 228, height: 32)
        }
        .frame(width: 539, height: 32)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 42, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .stroke(Color(hex: "#D4D2D1").opacity(0.55), lineWidth: 1)
        )
        .scaleEffect(scale, anchor: .topLeading)
        .frame(
            width: metricsToolbarReferenceWidth * scale,
            height: metricsToolbarReferenceHeight * scale,
            alignment: .topLeading
        )
    }

    private var colorControls: some View {
        HStack(spacing: 8) {
            ForEach(Constants.drawingColors) { drawingColor in
                Button {
                    selectedColorHex = drawingColor.hex
                    if tool == .eraser {
                        tool = .brush
                    }
                } label: {
                    colorSwatch(
                        drawingColor,
                        isSelected: selectedColorHex == drawingColor.hex && tool != .eraser
                    )
                }
                .buttonStyle(.plain)
                .help(drawingColor.name)
            }
        }
    }

    @ViewBuilder
    private func colorSwatch(_ drawingColor: DrawingColor, isSelected: Bool) -> some View {
        let color = Color(hex: drawingColor.hex)
        let isWhite = drawingColor.hex.uppercased() == "#FFFFFF"

        ZStack {
            if isSelected {
                Circle()
                    .strokeBorder(color, lineWidth: 4)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(isWhite ? 0.16 : 0.1), lineWidth: 0.5)
                    )

                Circle()
                    .fill(color)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(isWhite ? 0.16 : 0), lineWidth: isWhite ? 0.5 : 0)
                    )
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                    )
            }
        }
        .frame(width: 32, height: 32)
        .contentShape(Circle())
    }

    private var toolControls: some View {
        HStack(spacing: 8) {
            toolButton(.brush, assetName: "brush", help: "Brush")
            toolButton(.bucket, assetName: "bucket-droplet", help: "Bucket fill")

            Button {
                tool = tool == .eraser ? .brush : .eraser
            } label: {
                toolbarIcon("eraser")
            }
            .buttonStyle(FigmaToolButtonStyle(isSelected: tool == .eraser))
            .help("Eraser")

            Button {
                clearCanvas()
            } label: {
                toolbarIcon("trash-01")
            }
            .buttonStyle(FigmaToolButtonStyle())
            .help("Clear")

            Button {
                Task { await send() }
            } label: {
                Text(isSending ? "Saving" : "Update")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .frame(width: 68, height: 30)
                    .background(Color(hex: "#2B1F1B"), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isSending)
        }
    }

    private func toolButton(_ drawingTool: DrawingTool, assetName: String, help: String) -> some View {
        Button {
            tool = drawingTool
        } label: {
            toolbarIcon(assetName)
        }
        .help(help)
        .buttonStyle(FigmaToolButtonStyle(isSelected: tool == drawingTool))
    }

    private func toolbarIcon(_ assetName: String) -> some View {
        Image(assetName)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
            .foregroundStyle(Color(hex: "#101828"))
    }

    private func clearCanvas() {
        strokes.removeAll()
        flattenedCanvasData = nil
        canvasBackgroundHex = Constants.defaultCanvasBackgroundHex
    }

    private func performBucketFill(at point: CGPoint) {
        do {
            flattenedCanvasData = try CanvasRenderer.bucketFilledPNGData(
                from: strokes,
                backgroundHex: canvasBackgroundHex,
                baseImageData: flattenedCanvasData,
                fillPoint: point,
                fillHex: selectedColorHex
            )
            strokes.removeAll()
            canvasBackgroundHex = Constants.defaultCanvasBackgroundHex
        } catch {
            appState.errorMessage = "Couldn’t fill that area."
        }
    }

    private func send() async {
        guard !strokes.isEmpty || flattenedCanvasData != nil || canvasBackgroundHex != Constants.defaultCanvasBackgroundHex else {
            appState.errorMessage = "Draw something first."
            return
        }

        isSending = true
        defer { isSending = false }

        do {
            let pngData = try CanvasRenderer.pngData(
                from: strokes,
                backgroundHex: canvasBackgroundHex,
                baseImageData: flattenedCanvasData
            )
            await appState.sendDrawing(pngData: pngData)
        } catch {
            appState.errorMessage = "Couldn’t send. Check your connection and try again."
        }
    }

    private func layoutMetrics(for size: CGSize) -> DrawingLayoutMetrics {
        let horizontalPadding = metricsReferenceHorizontalPadding
        let topPadding = metricsReferenceTopPadding
        let bottomPadding = metricsReferenceBottomPadding
        let referenceContentHeight = metricsToolbarReferenceWidth + metricsReferenceStackSpacing + metricsToolbarReferenceHeight
        let availableWidth = max(metricsToolbarReferenceWidth, size.width - horizontalPadding * 2)
        let availableHeight = max(referenceContentHeight, size.height - topPadding - bottomPadding)
        let scale = max(1, min(availableWidth / metricsToolbarReferenceWidth, availableHeight / referenceContentHeight))
        let stackSpacing = metricsReferenceStackSpacing * scale
        let canvasWidth = metricsToolbarReferenceWidth * scale
        let contentWidth = canvasWidth
        let canvasHeight = canvasWidth * Constants.canvasSize.height / Constants.canvasSize.width
        let contentHeight = canvasHeight + stackSpacing + metricsToolbarReferenceHeight * scale

        return DrawingLayoutMetrics(
            scale: scale,
            contentWidth: contentWidth,
            contentHeight: contentHeight,
            canvasWidth: canvasWidth,
            canvasHeight: canvasHeight,
            horizontalPadding: horizontalPadding,
            topPadding: topPadding,
            bottomPadding: bottomPadding,
            stackSpacing: stackSpacing,
            statusOffset: metricsReferenceStatusOffset * scale
        )
    }

}

private let metricsReferenceWidth: CGFloat = 591
private let metricsReferenceHeight: CGFloat = 675
private let metricsReferenceHorizontalPadding: CGFloat = 16
private let metricsReferenceTopPadding: CGFloat = 28
private let metricsReferenceBottomPadding: CGFloat = 28
private let metricsReferenceStackSpacing: CGFloat = 12
private let metricsReferenceStatusOffset: CGFloat = 36
private let metricsToolbarReferenceWidth: CGFloat = 559
private let metricsToolbarReferenceHeight: CGFloat = 48

private struct FigmaToolButtonStyle: ButtonStyle {
    var isSelected = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 32, height: 32)
            .background(Color.white, in: Circle())
            .overlay(
                Circle()
                    .stroke(isSelected ? Color(hex: "#1F1F1F") : Color(hex: "#D4D2D1").opacity(0.4), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

private struct DrawingLayoutMetrics {
    let scale: CGFloat
    let contentWidth: CGFloat
    let contentHeight: CGFloat
    let canvasWidth: CGFloat
    let canvasHeight: CGFloat
    let horizontalPadding: CGFloat
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    let stackSpacing: CGFloat
    let statusOffset: CGFloat
}
