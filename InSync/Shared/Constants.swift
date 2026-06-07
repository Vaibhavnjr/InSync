import CoreGraphics
import Foundation

enum Constants {
    static let appName = "InSync"
    static let appGroupIdentifier = "49W487ZZQ7.com.vaibhavpant.insync.shared"
    static let widgetKind = "InSyncWidget"
    static let widgetImageFilename = "latest_partner_drawing.png"

    static let latestPartnerUpdatedAtKey = "latest_partner_updated_at"
    static let partnerLabelKey = "partner_label"

    static let canvasSize = CGSize(width: 512, height: 512)
    static let defaultCanvasBackgroundHex = "#FFFFFF"
    static let brushSize: CGFloat = 8
    static let eraserSize: CGFloat = 18
    static let bucketFillTolerance: UInt8 = 10

    static let pairWords = [
        "LOVE",
        "STAR",
        "MOON",
        "PINK",
        "BLUE",
        "HUGS",
        "WAVE",
        "TINY"
    ]

    static let drawingColors: [DrawingColor] = [
        DrawingColor(name: "Black", hex: "#1F1F1F"),
        DrawingColor(name: "Pink", hex: "#FF5EAB"),
        DrawingColor(name: "Red", hex: "#FF2B3A"),
        DrawingColor(name: "Blue", hex: "#1D7DFF"),
        DrawingColor(name: "Green", hex: "#00A665"),
        DrawingColor(name: "Yellow", hex: "#FCC300"),
        DrawingColor(name: "White", hex: "#FFFFFF")
    ]
}

struct DrawingColor: Identifiable, Hashable {
    var id: String { hex }
    let name: String
    let hex: String
}
