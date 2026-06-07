import CoreGraphics
import Foundation

struct Stroke: Identifiable, Codable, Equatable {
    let id: UUID
    var colorHex: String
    var points: [CGPoint]
    var isEraser: Bool

    init(id: UUID = UUID(), colorHex: String, points: [CGPoint] = [], isEraser: Bool = false) {
        self.id = id
        self.colorHex = colorHex
        self.points = points
        self.isEraser = isEraser
    }

    var lineWidth: CGFloat {
        isEraser ? Constants.eraserSize : Constants.brushSize
    }

    var displayHex: String {
        isEraser ? "#FFFFFF" : colorHex
    }
}

