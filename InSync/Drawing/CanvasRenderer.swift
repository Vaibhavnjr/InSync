import AppKit
import Foundation

enum CanvasRendererError: LocalizedError {
    case couldNotCreateBitmap
    case couldNotCreatePNG
    case invalidFillPoint

    var errorDescription: String? {
        switch self {
        case .couldNotCreateBitmap:
            return "Could not create drawing bitmap."
        case .couldNotCreatePNG:
            return "Could not export drawing as PNG."
        case .invalidFillPoint:
            return "Could not fill outside the drawing canvas."
        }
    }
}

enum CanvasRenderer {
    static func pngData(
        from strokes: [Stroke],
        backgroundHex: String = Constants.defaultCanvasBackgroundHex,
        baseImageData: Data? = nil,
        size: CGSize = Constants.canvasSize
    ) throws -> Data {
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw CanvasRendererError.couldNotCreateBitmap
        }

        guard let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
            throw CanvasRendererError.couldNotCreateBitmap
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphicsContext

        let context = graphicsContext.cgContext
        renderBase(backgroundHex: backgroundHex, baseImageData: baseImageData, size: size)

        // Match SwiftUI's top-left drawing coordinates when rendering to a bitmap.
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)

        context.setLineCap(.round)
        context.setLineJoin(.round)

        for stroke in strokes {
            render(stroke, backgroundHex: backgroundHex, in: context)
        }

        NSGraphicsContext.restoreGraphicsState()

        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw CanvasRendererError.couldNotCreatePNG
        }

        return data
    }

    static func bucketFilledPNGData(
        from strokes: [Stroke],
        backgroundHex: String,
        baseImageData: Data?,
        fillPoint: CGPoint,
        fillHex: String,
        size: CGSize = Constants.canvasSize
    ) throws -> Data {
        let currentPNGData = try pngData(
            from: strokes,
            backgroundHex: backgroundHex,
            baseImageData: baseImageData,
            size: size
        )

        return try floodFilledPNGData(
            currentPNGData,
            fillPoint: fillPoint,
            fillHex: fillHex,
            tolerance: Constants.bucketFillTolerance
        )
    }

    private static func renderBase(backgroundHex: String, baseImageData: Data?, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        NSColor(hex: backgroundHex).setFill()
        NSBezierPath(rect: rect).fill()

        guard let baseImageData,
              let image = NSImage(data: baseImageData) else {
            return
        }

        image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
    }

    private static func render(_ stroke: Stroke, backgroundHex: String, in context: CGContext) {
        guard let firstPoint = stroke.points.first else { return }

        let strokeHex = stroke.isEraser ? backgroundHex : stroke.colorHex
        context.setStrokeColor(NSColor(hex: strokeHex).cgColor)
        context.setFillColor(NSColor(hex: strokeHex).cgColor)
        context.setLineWidth(stroke.lineWidth)

        if stroke.points.count == 1 {
            let radius = stroke.lineWidth / 2
            let rect = CGRect(
                x: firstPoint.x - radius,
                y: firstPoint.y - radius,
                width: stroke.lineWidth,
                height: stroke.lineWidth
            )
            context.fillEllipse(in: rect)
            return
        }

        context.beginPath()
        context.move(to: firstPoint)

        for point in stroke.points.dropFirst() {
            context.addLine(to: point)
        }

        context.strokePath()
    }

    private static func floodFilledPNGData(
        _ pngData: Data,
        fillPoint: CGPoint,
        fillHex: String,
        tolerance: UInt8
    ) throws -> Data {
        guard let sourceImage = NSImage(data: pngData),
              let sourceCGImage = sourceImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw CanvasRendererError.couldNotCreateBitmap
        }

        let width = sourceCGImage.width
        let height = sourceCGImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw CanvasRendererError.couldNotCreateBitmap
        }

        context.draw(sourceCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let startX = Int(fillPoint.x.rounded(.down))
        let startY = Int(fillPoint.y.rounded(.down))

        guard startX >= 0, startX < width, startY >= 0, startY < height else {
            throw CanvasRendererError.invalidFillPoint
        }

        let fillColor = RGBAColor(hex: fillHex)
        let targetColor = color(in: pixels, width: width, bytesPerRow: bytesPerRow, x: startX, y: startY)

        guard !targetColor.isClose(to: fillColor, tolerance: tolerance) else {
            guard let cgImage = context.makeImage(),
                  let data = encodedPNGData(from: cgImage) else {
                throw CanvasRendererError.couldNotCreatePNG
            }
            return data
        }

        var stack = [PixelPoint(x: startX, y: startY)]
        var visited = [Bool](repeating: false, count: width * height)

        while let pixel = stack.popLast() {
            guard pixel.x >= 0, pixel.x < width, pixel.y >= 0, pixel.y < height else { continue }

            let visitedIndex = pixel.y * width + pixel.x
            guard !visited[visitedIndex] else { continue }
            visited[visitedIndex] = true

            let currentColor = color(in: pixels, width: width, bytesPerRow: bytesPerRow, x: pixel.x, y: pixel.y)
            guard currentColor.isClose(to: targetColor, tolerance: tolerance) else { continue }

            setColor(fillColor, in: &pixels, bytesPerRow: bytesPerRow, x: pixel.x, y: pixel.y)

            stack.append(PixelPoint(x: pixel.x + 1, y: pixel.y))
            stack.append(PixelPoint(x: pixel.x - 1, y: pixel.y))
            stack.append(PixelPoint(x: pixel.x, y: pixel.y + 1))
            stack.append(PixelPoint(x: pixel.x, y: pixel.y - 1))
        }

        guard let cgImage = context.makeImage(),
              let data = encodedPNGData(from: cgImage) else {
            throw CanvasRendererError.couldNotCreatePNG
        }

        return data
    }

    private static func color(
        in pixels: [UInt8],
        width: Int,
        bytesPerRow: Int,
        x: Int,
        y: Int
    ) -> RGBAColor {
        let index = y * bytesPerRow + x * 4
        return RGBAColor(
            red: pixels[index],
            green: pixels[index + 1],
            blue: pixels[index + 2],
            alpha: pixels[index + 3]
        )
    }

    private static func setColor(
        _ color: RGBAColor,
        in pixels: inout [UInt8],
        bytesPerRow: Int,
        x: Int,
        y: Int
    ) {
        let index = y * bytesPerRow + x * 4
        pixels[index] = color.red
        pixels[index + 1] = color.green
        pixels[index + 2] = color.blue
        pixels[index + 3] = color.alpha
    }

    private static func encodedPNGData(from cgImage: CGImage) -> Data? {
        let imageRep = NSBitmapImageRep(cgImage: cgImage)
        return imageRep.representation(using: .png, properties: [:])
    }
}

private struct PixelPoint {
    let x: Int
    let y: Int
}

private struct RGBAColor {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8

    init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8 = 255) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")))
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)

        red = UInt8((value >> 16) & 0xFF)
        green = UInt8((value >> 8) & 0xFF)
        blue = UInt8(value & 0xFF)
        alpha = 255
    }

    func isClose(to other: RGBAColor, tolerance: UInt8) -> Bool {
        let tolerance = Int(tolerance)
        return abs(Int(red) - Int(other.red)) <= tolerance
            && abs(Int(green) - Int(other.green)) <= tolerance
            && abs(Int(blue) - Int(other.blue)) <= tolerance
            && abs(Int(alpha) - Int(other.alpha)) <= tolerance
    }
}
