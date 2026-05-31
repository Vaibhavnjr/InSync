import Foundation

struct DrawingMetadata: Equatable {
    let imagePath: String
    let updatedAt: Date

    var isEmpty: Bool {
        imagePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

